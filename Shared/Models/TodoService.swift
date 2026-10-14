import Foundation
import SwiftData
import RPGTodoCore

/// 「今日のみ」か「今後すべて」か（繰り返し Todo の編集・削除で選ぶ）。
enum RecurrenceScope {
    case thisDayOnly
    case allFuture
}

/// Todo の追加・変更・削除・繰り返し生成。画面はここを通して `ModelContext` を操作する。
@MainActor
enum TodoService {
    // MARK: 繰り返しの生成

    /// 繰り返し設定から、`today` までの Todo を生成する。何度呼んでも二重には作らない（要件 D-05）。
    /// アプリを開かなかった間の日も、前回の翌日からまとめて生成する。
    static func generateRecurringTodos(through today: LocalDate, in context: ModelContext) {
        let recurrences = (try? context.fetch(FetchDescriptor<RecurrenceItem>())) ?? []
        guard !recurrences.isEmpty else { return }

        let existing = (try? context.fetch(FetchDescriptor<TodoItem>())) ?? []
        var generated = Set(existing.compactMap { todo in
            todo.recurrenceID.map { Self.key($0, todo.dateKey) }
        })

        for recurrence in recurrences {
            for date in recurrence.schedule.datesToGenerate(through: today)
            where generated.insert(Self.key(recurrence.id, date.dayKey)).inserted {
                context.insert(TodoItem(
                    title: recurrence.title,
                    date: date,
                    timeMinutes: recurrence.timeMinutes,
                    category: recurrence.category,
                    notificationEnabled: recurrence.notificationEnabled,
                    recurrenceID: recurrence.id
                ))
            }
            // 一時停止中も進めておく（再開したときに停止中の分をさかのぼらない）。
            if recurrence.lastGeneratedDateKey.map({ $0 < today.dayKey }) ?? true {
                recurrence.lastGeneratedDateKey = today.dayKey
            }
        }
        try? context.save()
    }

    private static func key(_ id: UUID, _ dayKey: Int) -> String { "\(id.uuidString)-\(dayKey)" }

    // MARK: 追加

    /// シートの内容から Todo を作る。繰り返しありなら、設定も一緒に作る。
    static func create(from draft: TodoDraft, today: LocalDate, in context: ModelContext) {
        let date = draft.localDate
        var recurrenceID: UUID?

        if let rule = draft.rule {
            let recurrence = RecurrenceItem(
                title: draft.trimmedTitle,
                timeMinutes: draft.timeMinutes,
                category: draft.category,
                notificationEnabled: false,
                rule: rule,
                startDate: date
            )
            // 選んだ日の分はルールに合わなくても作る（作った Todo が消えて見えないように）。
            // 次回からは翌日以降の分を生成する。
            recurrence.lastGeneratedDateKey = date.dayKey
            context.insert(recurrence)
            recurrenceID = recurrence.id
        }

        context.insert(TodoItem(
            title: draft.trimmedTitle,
            date: date,
            timeMinutes: draft.timeMinutes,
            category: draft.category,
            recurrenceID: recurrenceID
        ))
        try? context.save()
        generateRecurringTodos(through: today, in: context)
    }

    // MARK: 変更

    static func update(
        _ todo: TodoItem,
        from draft: TodoDraft,
        scope: RecurrenceScope,
        in context: ModelContext
    ) {
        todo.title = draft.trimmedTitle
        todo.date = draft.localDate
        todo.timeMinutes = draft.timeMinutes
        todo.category = draft.category
        todo.updatedAt = .now

        if let recurrence = recurrence(for: todo, in: context) {
            if scope == .allFuture {
                recurrence.title = draft.trimmedTitle
                recurrence.timeMinutes = draft.timeMinutes
                recurrence.category = draft.category
                if let rule = draft.rule {
                    recurrence.rule = rule
                } else {
                    // 「繰り返しなし」に変えた: この日を最後に、以降は作らない。
                    recurrence.endDateKey = todo.dateKey
                }
            }
        } else if let rule = draft.rule {
            // 繰り返しなしの Todo に、あとから繰り返しを付けた。
            let recurrence = RecurrenceItem(
                title: draft.trimmedTitle,
                timeMinutes: draft.timeMinutes,
                category: draft.category,
                notificationEnabled: false,
                rule: rule,
                startDate: todo.date
            )
            recurrence.lastGeneratedDateKey = todo.dateKey
            context.insert(recurrence)
            todo.recurrenceID = recurrence.id
        }
        try? context.save()
    }

    // MARK: 削除

    /// 繰り返し Todo は `scope` で「この日だけ削除」か「繰り返しを終了」かを選ぶ。
    static func delete(_ todo: TodoItem, scope: RecurrenceScope, in context: ModelContext) {
        if let recurrence = recurrence(for: todo, in: context) {
            switch scope {
            case .thisDayOnly:
                if !recurrence.skippedDateKeys.contains(todo.dateKey) {
                    recurrence.skippedDateKeys.append(todo.dateKey)
                }
            case .allFuture:
                // この日以降は作らない。この日の分も削除する。
                recurrence.endDateKey = todo.date.addingDays(-1).dayKey
            }
        }
        context.delete(todo)
        try? context.save()
    }

    // MARK: 完了

    static func toggle(_ todo: TodoItem, in context: ModelContext) {
        todo.setCompleted(!todo.isCompleted)
        try? context.save()
    }

    // MARK: 今日に移す

    /// 過去日の未完了 Todo を、今日の新しい Todo として複製する。元の Todo は「繰越済」にして、元の日の達成率は変えない。
    static func carryOver(_ todo: TodoItem, to today: LocalDate, in context: ModelContext) {
        guard todo.carriedOverTo == nil, todo.date < today else { return }
        let copy = TodoItem(
            title: todo.title,
            date: today,
            timeMinutes: todo.timeMinutes,
            category: todo.category
        )
        context.insert(copy)
        todo.carriedOverTo = copy.id
        try? context.save()
    }

    // MARK: 検索

    static func recurrence(for todo: TodoItem, in context: ModelContext) -> RecurrenceItem? {
        guard let id = todo.recurrenceID else { return nil }
        let descriptor = FetchDescriptor<RecurrenceItem>(predicate: #Predicate { $0.id == id })
        return try? context.fetch(descriptor).first
    }
}
