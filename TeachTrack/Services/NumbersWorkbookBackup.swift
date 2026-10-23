import Foundation
import SwiftUI
import UniformTypeIdentifiers
import CryptoKit
import zlib

/// An Excel workbook that Numbers can open. Each model has its own editable sheet.
/// IDs are kept in the sheets so a round trip retains every relationship.
enum NumbersWorkbookBackup {
    static let contentType = UTType(filenameExtension: "xlsx")
        ?? UTType(importedAs: "org.openxmlformats.spreadsheetml.sheet")

    enum BackupError: LocalizedError {
        case invalidWorkbook
        case unsupportedVersion
        case missingSheet(String)
        case invalidValue(String)
        case duplicateID(String)
        case tooLarge

        var errorDescription: String? {
            switch self {
            case .invalidWorkbook: "This is not a valid Teacher's Organizer workbook."
            case .unsupportedVersion: "This workbook uses an unsupported backup format."
            case .missingSheet(let name): "The workbook is missing the \(name) sheet."
            case .invalidValue(let value): "The workbook contains an invalid value: \(value)."
            case .duplicateID(let name): "The \(name) sheet contains duplicate IDs."
            case .tooLarge: "The workbook is too large to import safely."
            }
        }
    }

    private struct Table {
        let name: String
        let key: String
        let columns: [String]
    }

    private static let tables: [Table] = [
        .init(name: "Organizations", key: "organizations",
              columns: ["id", "name", "type", "phone", "email", "address", "notes", "isActive"]),
        .init(name: "Students", key: "students",
              columns: ["id", "firstName", "lastName", "phone", "email", "notes", "type", "isActive"]),
        .init(name: "Groups", key: "groups",
              columns: ["id", "name", "revenueModel", "fixedLessonRate",
                        "organizationAttendanceRate", "ratePerStudent", "notes", "isActive", "organizationID"]),
        .init(name: "Contacts", key: "contacts",
              columns: ["id", "studentID", "name", "relationship", "phone", "email", "notes"]),
        .init(name: "Enrollments", key: "enrollments",
              columns: ["id", "studentID", "groupID", "lessonPrice", "enrollmentDate", "endDate", "isActive"]),
        .init(name: "Schedule Rules", key: "rules",
              columns: ["id", "groupID", "weekday", "startHour", "startMinute", "durationMinutes", "isActive"]),
        .init(name: "Schedule Exceptions", key: "exceptions",
              columns: ["id", "ruleID", "date", "isActive"]),
        .init(name: "Lessons", key: "lessons",
              columns: ["id", "groupID", "startDate", "endDate", "status", "source",
                        "generatedRuleID", "isManuallyModified", "notes", "billedRate"]),
        .init(name: "Attendance", key: "attendances",
              columns: ["id", "studentID", "lessonID", "status", "makeupSourceID", "notes"]),
        .init(name: "Attendance Revisions", key: "revisions",
              columns: ["id", "attendanceID", "status", "recordedAt", "notes"]),
        .init(name: "Transactions", key: "transactions",
              columns: ["id", "date", "type", "amount", "studentID", "organizationID", "lessonID", "notes"]),
        .init(name: "Student Notes", key: "studentNotes",
              columns: ["id", "studentID", "text", "createdAt"]),
        .init(name: "Lesson Notes", key: "lessonNotes",
              columns: ["id", "lessonID", "text", "createdAt"])
    ]

    private static let integerColumns: Set<String> = [
        "weekday", "startHour", "startMinute", "durationMinutes"
    ]
    private static let decimalColumns: Set<String> = [
        "fixedLessonRate", "organizationAttendanceRate", "ratePerStudent",
        "lessonPrice", "billedRate", "amount"
    ]
    private static let booleanColumns: Set<String> = ["isActive", "isManuallyModified"]
    private static let marker = "Teacher's Organizer database backup"
    private static let formatVersion = 2
    private static let maxWorkbookBytes = 80_000_000

    private static let newStudentHeaders = [
        "First Name", "Last Name", "Type", "Organization", "Lesson Rate",
        "Phone", "Email", "Notes"
    ]

    struct NewStudent {
        let student: DatabaseSnapshot.StudentRow
        let organizationID: UUID?
        let lessonRate: Decimal?
        let groupID: UUID?
        let enrollmentID: UUID?

        func add(to snapshot: inout DatabaseSnapshot) {
            snapshot.students.append(student)
            guard let organizationID, let lessonRate, let groupID, let enrollmentID else { return }
            snapshot.groups.append(.init(
                id: groupID, name: "\(student.firstName) \(student.lastName)",
                revenueModel: .perStudent, fixedLessonRate: nil,
                organizationAttendanceRate: nil, ratePerStudent: lessonRate,
                notes: nil, isActive: true, organizationID: organizationID
            ))
            snapshot.enrollments.append(.init(
                id: enrollmentID, studentID: student.id, groupID: groupID,
                lessonPrice: lessonRate, enrollmentDate: .now,
                endDate: nil, isActive: true
            ))
        }
    }

    private static func title(_ key: String) -> String {
        let names = [
            "id": "Record ID", "firstName": "First Name", "lastName": "Last Name",
            "isActive": "Active", "revenueModel": "Payment Model",
            "fixedLessonRate": "Fixed Lesson Rate", "organizationAttendanceRate": "Attendance Rate",
            "ratePerStudent": "Rate Per Student", "lessonPrice": "Lesson Price",
            "enrollmentDate": "Enrollment Date", "endDate": "End Date",
            "startDate": "Start Date", "startHour": "Start Hour",
            "startMinute": "Start Minute", "durationMinutes": "Duration (Minutes)",
            "generatedRuleID": "Schedule Rule ID", "isManuallyModified": "Manually Modified",
            "billedRate": "Billed Rate", "recordedAt": "Recorded At",
            "createdAt": "Created At", "makeupSourceID": "Makeup Source ID",
            "studentID": "Student ID", "organizationID": "Organization ID",
            "groupID": "Group ID", "ruleID": "Rule ID",
            "lessonID": "Lesson ID", "attendanceID": "Attendance ID"
        ]
        return names[key] ?? key.capitalized
    }

    private static func isID(_ key: String) -> Bool {
        key == "id" || key.hasSuffix("ID")
    }

    private static func displayTitle(_ key: String) -> String {
        title(key).replacingOccurrences(of: " ID", with: "")
    }

    private static func headers(for table: Table) -> [String] {
        table.columns.flatMap { key in
            isID(key) && key != "id" ? [title(key), displayTitle(key)] : [title(key)]
        }
    }

    private static func hiddenColumns(for table: Table) -> Set<Int> {
        var hidden = Set<Int>()
        var index = 0
        for key in table.columns {
            if isID(key) { hidden.insert(index) }
            index += key == "id" || !isID(key) ? 1 : 2
        }
        return hidden
    }

    private static func displayValue(for key: String, source: [String: Any],
                                     in snapshot: DatabaseSnapshot) -> String {
        guard let raw = source[key] as? String, let id = UUID(uuidString: raw) else { return "" }
        func student(_ value: UUID) -> String {
            guard let row = snapshot.students.first(where: { $0.id == value }) else { return "" }
            return "\(row.firstName) \(row.lastName)".trimmingCharacters(in: .whitespaces)
        }
        func group(_ value: UUID) -> String {
            snapshot.groups.first(where: { $0.id == value })?.name ?? ""
        }
        func lesson(_ value: UUID) -> String {
            guard let row = snapshot.lessons.first(where: { $0.id == value }) else { return "" }
            return "\(group(row.groupID)) · \(row.startDate.formatted(date: .abbreviated, time: .shortened))"
        }
        switch key {
        case "studentID": return student(id)
        case "organizationID": return snapshot.organizations.first(where: { $0.id == id })?.name ?? ""
        case "groupID": return group(id)
        case "lessonID": return lesson(id)
        case "ruleID", "generatedRuleID":
            guard let row = snapshot.rules.first(where: { $0.id == id }) else { return "" }
            return "\(group(row.groupID)) · \(row.weekday.rawValue) \(row.startHour):\(String(format: "%02d", row.startMinute))"
        case "attendanceID", "makeupSourceID":
            guard let row = snapshot.attendances.first(where: { $0.id == id }) else { return "" }
            return "\(student(row.studentID)) · \(lesson(row.lessonID))"
        default: return ""
        }
    }

    static func make(_ snapshot: DatabaseSnapshot) throws -> Data {
        try snapshot.validate()
        let root = try JSONSerialization.jsonObject(with: encode(snapshot)) as? [String: Any]
        guard let root else { throw BackupError.invalidWorkbook }
        var sheets: [(String, Data)] = []

        let overview: [[Cell]] = [
            [.text(marker), .number(String(formatVersion))],
            [.text("Created"), .text(ISO8601DateFormatter().string(from: Date()))],
            [.text("Records"), .number(String(snapshot.recordCount))],
            [.text("Workbook ID"), .text(UUID().uuidString)],
            [.text("Edit visible data. Hidden IDs keep relationships intact; do not change them.")],
            [.text("Add students on New Students. Private students require a private organization and lesson rate.")],
            [.text("Import replaces the complete database on this device.")],
            [.text("If cloud storage is enabled, the imported data will sync to iCloud.")]
        ]
        sheets.append(("Overview", worksheet(overview)))

        for table in tables {
            let sourceRows = root[table.key] as? [[String: Any]] ?? []
            var rows: [[Cell]] = [headers(for: table).map { .text($0) }]
            rows.reserveCapacity(sourceRows.count + 1)
            for source in sourceRows {
                rows.append(table.columns.flatMap { column -> [Cell] in
                    guard let value = source[column] else {
                        return isID(column) && column != "id" ? [.empty, .empty] : [.empty]
                    }
                    let cell: Cell
                    if booleanColumns.contains(column) {
                        cell = .boolean((value as? NSNumber)?.boolValue == true)
                    } else if integerColumns.contains(column) || decimalColumns.contains(column) {
                        cell = .number(String(describing: value))
                    } else {
                        cell = .text(String(describing: value))
                    }
                    return isID(column) && column != "id"
                        ? [cell, .text(displayValue(for: column, source: source, in: snapshot))]
                        : [cell]
                })
            }
            sheets.append((table.name, worksheet(rows, hiddenColumns: hiddenColumns(for: table))))
        }
        sheets.append(("New Students", worksheet([newStudentHeaders.map { .text($0) }])))
        return try zipWorkbook(sheets)
    }

    static func read(_ data: Data) throws -> DatabaseSnapshot {
        let book = try Workbook(data)

        var root: [String: Any] = ["version": DatabaseSnapshot.currentVersion]
        for table in tables {
            let sheet = try book.rows(named: table.name)
            let expected = book.version == 1 ? table.columns : headers(for: table)
            guard let header = sheet.first, header == expected else {
                throw BackupError.invalidValue("\(table.name) column names")
            }
            var records: [[String: Any]] = []
            var ids = Set<String>()
            for values in sheet.dropFirst() {
                if values.allSatisfy({ $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
                    continue
                }
                var record: [String: Any] = [:]
                var index = 0
                for column in table.columns {
                    let value = index < values.count ? values[index] : ""
                    index += book.version == 2 && isID(column) && column != "id" ? 2 : 1
                    if value.isEmpty { continue }
                    if booleanColumns.contains(column) {
                        switch value.lowercased() {
                        case "true", "1": record[column] = true
                        case "false", "0": record[column] = false
                        default: throw BackupError.invalidValue("\(table.name).\(column)")
                        }
                    } else if integerColumns.contains(column) {
                        guard let number = Int(value) else {
                            throw BackupError.invalidValue("\(table.name).\(column)")
                        }
                        record[column] = number
                    } else if decimalColumns.contains(column) {
                        guard let number = Decimal(string: value, locale: Locale(identifier: "en_US_POSIX")) else {
                            throw BackupError.invalidValue("\(table.name).\(column)")
                        }
                        record[column] = NSDecimalNumber(decimal: number)
                    } else {
                        record[column] = value
                    }
                }
                guard let id = record["id"] as? String, UUID(uuidString: id) != nil else {
                    throw BackupError.invalidValue("\(table.name).id")
                }
                guard ids.insert(id.lowercased()).inserted else {
                    throw BackupError.duplicateID(table.name)
                }
                records.append(record)
            }
            root[table.key] = records
        }
        guard JSONSerialization.isValidJSONObject(root) else { throw BackupError.invalidWorkbook }
        let json = try JSONSerialization.data(withJSONObject: root)
        var snapshot = try decoder().decode(DatabaseSnapshot.self, from: json)
        if book.version == 2 {
            for row in try newStudents(in: book) {
                guard !snapshot.students.contains(where: { $0.id == row.student.id }) else {
                    throw BackupError.duplicateID("Students / New Students")
                }
                row.add(to: &snapshot)
            }
        }
        try snapshot.validate()
        return snapshot
    }

    /// Reads only the add-only student list; no existing database sheet is imported.
    static func readNewStudents(_ data: Data) throws -> [NewStudent] {
        let book = try Workbook(data)
        guard book.version == 2 else { throw BackupError.unsupportedVersion }
        return try newStudents(in: book)
    }

    private static func newStudents(in book: Workbook) throws -> [NewStudent] {
        let rows = try book.rows(named: "New Students")
        guard rows.first == newStudentHeaders else {
            throw BackupError.invalidValue("New Students column names")
        }
        let organizations = try book.rows(named: "Organizations")
        guard organizations.first == headers(for: tables[0]) else {
            throw BackupError.invalidValue("Organizations column names")
        }
        return try rows.dropFirst().enumerated().compactMap { offset, values in
            let values = (0..<newStudentHeaders.count).map { index in
                (index < values.count ? values[index] : "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            if values.allSatisfy(\.isEmpty) { return nil }
            guard !values[0].isEmpty, !values[1].isEmpty else {
                throw BackupError.invalidValue("New Students row \(offset + 2): first and last name are required")
            }
            let kind = values[2].lowercased()
            guard kind.isEmpty || kind == "regular" || kind == "private" ||
                    kind == "private client" else {
                throw BackupError.invalidValue("New Students row \(offset + 2): Type must be Regular or Private")
            }
            let isPrivate = kind == "private" || kind == "private client"
            var organizationID: UUID?
            var lessonRate: Decimal?
            if isPrivate {
                let matches = organizations.dropFirst().filter { row in
                    row.count > 2 && row[1].localizedCaseInsensitiveCompare(values[3]) == .orderedSame &&
                    row[2] == OrganizationType.privateClient.rawValue
                }
                guard matches.count == 1, let rawID = matches.first?.first,
                      let id = UUID(uuidString: rawID) else {
                    throw BackupError.invalidValue("New Students row \(offset + 2): choose one existing private organization")
                }
                guard let rate = Decimal(string: values[4], locale: Locale(identifier: "en_US_POSIX")),
                      rate > 0 else {
                    throw BackupError.invalidValue("New Students row \(offset + 2): enter a positive lesson rate")
                }
                organizationID = id
                lessonRate = rate
            } else if !values[3].isEmpty || !values[4].isEmpty {
                throw BackupError.invalidValue("New Students row \(offset + 2): Organization and Lesson Rate are for Private students")
            }
            let rowNumber = offset + 2
            let student = DatabaseSnapshot.StudentRow(
                id: stableID(book.id, rowNumber, "student"),
                firstName: values[0], lastName: values[1],
                phone: values[5].isEmpty ? nil : values[5],
                email: values[6].isEmpty ? nil : values[6],
                notes: values[7].isEmpty ? nil : values[7],
                type: isPrivate ? .privateClient : .regular, isActive: true
            )
            return NewStudent(
                student: student, organizationID: organizationID,
                lessonRate: lessonRate,
                groupID: isPrivate ? stableID(book.id, rowNumber, "group") : nil,
                enrollmentID: isPrivate ? stableID(book.id, rowNumber, "enrollment") : nil
            )
        }
    }

    private static func stableID(_ workbookID: UUID, _ row: Int, _ kind: String) -> UUID {
        let bytes = Array(SHA256.hash(data: Data("\(workbookID.uuidString):\(row):\(kind)".utf8)).prefix(16))
        return UUID(uuid: (bytes[0], bytes[1], bytes[2], bytes[3],
                           bytes[4], bytes[5], bytes[6], bytes[7],
                           bytes[8], bytes[9], bytes[10], bytes[11],
                           bytes[12], bytes[13], bytes[14], bytes[15]))
    }

    private struct Workbook {
        var version = 0
        var id = UUID()
        let files: [String: Data]
        let sheetNames: [String: String]
        let paths: [String: String]
        let sharedStrings: [String]

        init(_ data: Data) throws {
            guard data.count <= maxWorkbookBytes else { throw BackupError.tooLarge }
            files = try StoredZip.read(data)
            guard let workbook = files["xl/workbook.xml"],
                  let relationships = files["xl/_rels/workbook.xml.rels"] else {
                throw BackupError.invalidWorkbook
            }
            sheetNames = try WorkbookXML.sheets(workbook)
            paths = try WorkbookXML.relationships(relationships)
            if let stringsXML = files["xl/sharedStrings.xml"] {
                sharedStrings = try WorkbookXML.sharedStrings(stringsXML)
            } else {
                sharedStrings = []
            }
            let overview = try rows(named: "Overview")
            guard overview.first?.first == marker else { throw BackupError.invalidWorkbook }
            guard let number = overview.first?.dropFirst().first.flatMap(Int.init),
                  number == 1 || number == formatVersion else {
                throw BackupError.unsupportedVersion
            }
            version = number
            if number == 2 {
                guard let rawID = overview.first(where: { $0.first == "Workbook ID" })?.dropFirst().first,
                      let uuid = UUID(uuidString: rawID) else {
                    throw BackupError.invalidValue("Workbook ID")
                }
                id = uuid
            } else {
                id = UUID()
            }
        }

        func rows(named name: String) throws -> [[String]] {
            guard let relationID = sheetNames[name],
                  let path = paths[relationID],
                  let xml = files[path] else { throw BackupError.missingSheet(name) }
            return try WorkbookXML.rows(xml, sharedStrings: sharedStrings)
        }
    }

    private static func encode(_ snapshot: DatabaseSnapshot) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, container in
            var value = container.singleValueContainer()
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            try value.encode(formatter.string(from: date))
        }
        return try encoder.encode(snapshot)
    }

    private static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { container in
            let value = try container.singleValueContainer().decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: value) { return date }
            formatter.formatOptions = [.withInternetDateTime]
            guard let date = formatter.date(from: value) else {
                throw BackupError.invalidValue("date \(value)")
            }
            return date
        }
        return decoder
    }

    private enum Cell {
        case text(String)
        case number(String)
        case boolean(Bool)
        case empty
    }

    private static func worksheet(_ rows: [[Cell]], hiddenColumns: Set<Int> = []) -> Data {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"
        xml += "<worksheet xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\">"
        xml += "<sheetViews><sheetView workbookViewId=\"0\"><pane ySplit=\"1\" topLeftCell=\"A2\" activePane=\"bottomLeft\" state=\"frozen\"/></sheetView></sheetViews>"
        xml += "<sheetFormatPr defaultRowHeight=\"18\"/><cols>"
        let columnCount = rows.map(\.count).max() ?? 1
        for index in 0..<columnCount {
            xml += "<col min=\"\(index + 1)\" max=\"\(index + 1)\" width=\"\(hiddenColumns.contains(index) ? 4 : 24)\" customWidth=\"1\""
            if hiddenColumns.contains(index) { xml += " hidden=\"1\"" }
            xml += "/>"
        }
        xml += "</cols><sheetData>"
        for (rowIndex, row) in rows.enumerated() {
            xml += "<row r=\"\(rowIndex + 1)\">"
            for (columnIndex, cell) in row.enumerated() {
                let reference = "\(columnName(columnIndex))\(rowIndex + 1)"
                let style = rowIndex == 0 ? " s=\"1\"" : (rowIndex.isMultiple(of: 2) ? " s=\"2\"" : "")
                switch cell {
                case .text(let value):
                    xml += "<c r=\"\(reference)\" t=\"inlineStr\"\(style)><is><t xml:space=\"preserve\">\(escape(value))</t></is></c>"
                case .number(let value):
                    xml += "<c r=\"\(reference)\"\(style)><v>\(escape(value))</v></c>"
                case .boolean(let value):
                    xml += "<c r=\"\(reference)\" t=\"b\"\(style)><v>\(value ? "1" : "0")</v></c>"
                case .empty:
                    break
                }
            }
            xml += "</row>"
        }
        xml += "</sheetData></worksheet>"
        return Data(xml.utf8)
    }

    private static func columnName(_ index: Int) -> String {
        var value = index + 1
        var result = ""
        while value > 0 {
            value -= 1
            result = String(UnicodeScalar(65 + value % 26)!) + result
            value /= 26
        }
        return result
    }

    private static func escape(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }

    private static func zipWorkbook(_ sheets: [(String, Data)]) throws -> Data {
        let spreadsheetNamespace = "http://schemas.openxmlformats.org/spreadsheetml/2006/main"
        let relationshipNamespace = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
        var workbook = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"
        workbook += "<workbook xmlns=\"\(spreadsheetNamespace)\" xmlns:r=\"\(relationshipNamespace)\"><sheets>"
        var relationships = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"
        relationships += "<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\">"
        var contentTypes = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"
        contentTypes += "<Types xmlns=\"http://schemas.openxmlformats.org/package/2006/content-types\">"
        contentTypes += "<Default Extension=\"rels\" ContentType=\"application/vnd.openxmlformats-package.relationships+xml\"/>"
        contentTypes += "<Default Extension=\"xml\" ContentType=\"application/xml\"/>"
        contentTypes += "<Override PartName=\"/xl/workbook.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml\"/>"
        contentTypes += "<Override PartName=\"/xl/styles.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml\"/>"
        var files: [(String, Data)] = []
        for (index, sheet) in sheets.enumerated() {
            let number = index + 1
            workbook += "<sheet name=\"\(escape(sheet.0))\" sheetId=\"\(number)\" r:id=\"rId\(number)\"/>"
            relationships += "<Relationship Id=\"rId\(number)\" Type=\"\(relationshipNamespace)/worksheet\" Target=\"worksheets/sheet\(number).xml\"/>"
            contentTypes += "<Override PartName=\"/xl/worksheets/sheet\(number).xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml\"/>"
            files.append(("xl/worksheets/sheet\(number).xml", sheet.1))
        }
        workbook += "</sheets></workbook>"
        relationships += "<Relationship Id=\"rIdStyles\" Type=\"\(relationshipNamespace)/styles\" Target=\"styles.xml\"/></Relationships>"
        contentTypes += "</Types>"
        let packageRels = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
        <Relationship Id="rIdWorkbook" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
        </Relationships>
        """
        let styles = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
        <fonts count="2"><font><sz val="11"/><name val="Aptos"/></font><font><b/><sz val="11"/><color rgb="FFFFFFFF"/><name val="Aptos"/></font></fonts>
        <fills count="4"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill><fill><patternFill patternType="solid"><fgColor rgb="FF24539A"/><bgColor indexed="64"/></patternFill></fill><fill><patternFill patternType="solid"><fgColor rgb="FFF0F5FC"/><bgColor indexed="64"/></patternFill></fill></fills>
        <borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>
        <cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
        <cellXfs count="3"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/><xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0" applyFill="1"/><xf numFmtId="0" fontId="0" fillId="3" borderId="0" xfId="0" applyFill="1"/></cellXfs>
        <cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>
        </styleSheet>
        """
        files.append(("[Content_Types].xml", Data(contentTypes.utf8)))
        files.append(("_rels/.rels", Data(packageRels.utf8)))
        files.append(("xl/workbook.xml", Data(workbook.utf8)))
        files.append(("xl/_rels/workbook.xml.rels", Data(relationships.utf8)))
        files.append(("xl/styles.xml", Data(styles.utf8)))
        return try StoredZip.write(files)
    }
}

struct NumbersWorkbookDocument: FileDocument {
    static var readableContentTypes: [UTType] { [NumbersWorkbookBackup.contentType] }
    var data: Data

    init(data: Data) { self.data = data }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw NumbersWorkbookBackup.BackupError.invalidWorkbook
        }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

/// Minimal ZIP reader/writer for OpenXML workbooks. Export uses stored entries;
/// import also accepts the deflated entries produced by Numbers.
enum StoredZip {
    private struct DirectoryEntry {
        let name: String
        let crc: UInt32
        let size: Int
        let offset: Int
    }

    static func write(_ files: [(String, Data)]) throws -> Data {
        var archive = Data()
        var directory: [DirectoryEntry] = []
        for (name, content) in files {
            guard let nameData = name.data(using: .utf8),
                  nameData.count <= UInt16.max,
                  content.count <= UInt32.max,
                  archive.count <= UInt32.max else {
                throw NumbersWorkbookBackup.BackupError.tooLarge
            }
            let checksum = crc(content)
            directory.append(.init(name: name, crc: checksum,
                                   size: content.count, offset: archive.count))
            archive.appendLE(UInt32(0x04034b50))
            archive.appendLE(UInt16(20))
            archive.appendLE(UInt16(0x0800))
            archive.appendLE(UInt16(0))
            archive.appendLE(UInt16(0))
            archive.appendLE(UInt16(0))
            archive.appendLE(checksum)
            archive.appendLE(UInt32(content.count))
            archive.appendLE(UInt32(content.count))
            archive.appendLE(UInt16(nameData.count))
            archive.appendLE(UInt16(0))
            archive.append(nameData)
            archive.append(content)
        }
        let directoryOffset = archive.count
        for item in directory {
            let name = Data(item.name.utf8)
            archive.appendLE(UInt32(0x02014b50))
            archive.appendLE(UInt16(20))
            archive.appendLE(UInt16(20))
            archive.appendLE(UInt16(0x0800))
            archive.appendLE(UInt16(0))
            archive.appendLE(UInt16(0))
            archive.appendLE(UInt16(0))
            archive.appendLE(item.crc)
            archive.appendLE(UInt32(item.size))
            archive.appendLE(UInt32(item.size))
            archive.appendLE(UInt16(name.count))
            archive.appendLE(UInt16(0))
            archive.appendLE(UInt16(0))
            archive.appendLE(UInt16(0))
            archive.appendLE(UInt16(0))
            archive.appendLE(UInt32(0))
            archive.appendLE(UInt32(item.offset))
            archive.append(name)
        }
        guard directory.count <= UInt16.max,
              directoryOffset <= UInt32.max,
              archive.count - directoryOffset <= UInt32.max else {
            throw NumbersWorkbookBackup.BackupError.tooLarge
        }
        let directorySize = archive.count - directoryOffset
        archive.appendLE(UInt32(0x06054b50))
        archive.appendLE(UInt16(0))
        archive.appendLE(UInt16(0))
        archive.appendLE(UInt16(directory.count))
        archive.appendLE(UInt16(directory.count))
        archive.appendLE(UInt32(directorySize))
        archive.appendLE(UInt32(directoryOffset))
        archive.appendLE(UInt16(0))
        return archive
    }

    static func read(_ data: Data) throws -> [String: Data] {
        guard data.count >= 22, data.count <= 80_000_000 else {
            throw NumbersWorkbookBackup.BackupError.invalidWorkbook
        }
        let earliest = max(0, data.count - 65_557)
        var end: Int?
        for offset in stride(from: data.count - 22, through: earliest, by: -1) {
            if try data.uint32(at: offset) == 0x06054b50 {
                end = offset
                break
            }
        }
        guard let end else { throw NumbersWorkbookBackup.BackupError.invalidWorkbook }
        let count = Int(try data.uint16(at: end + 10))
        let directorySize = Int(try data.uint32(at: end + 12))
        var cursor = Int(try data.uint32(at: end + 16))
        guard count <= 1000, cursor <= end,
              directorySize == end - cursor else {
            throw NumbersWorkbookBackup.BackupError.invalidWorkbook
        }
        var files: [String: Data] = [:]
        var totalUncompressed = 0
        for _ in 0..<count {
            guard try data.uint32(at: cursor) == 0x02014b50 else {
                throw NumbersWorkbookBackup.BackupError.invalidWorkbook
            }
            let method = try data.uint16(at: cursor + 10)
            let checksum = try data.uint32(at: cursor + 16)
            let compressedSize = Int(try data.uint32(at: cursor + 20))
            let size = Int(try data.uint32(at: cursor + 24))
            let nameLength = Int(try data.uint16(at: cursor + 28))
            let extraLength = Int(try data.uint16(at: cursor + 30))
            let commentLength = Int(try data.uint16(at: cursor + 32))
            let localOffset = Int(try data.uint32(at: cursor + 42))
            let nameData = try data.bytes(at: cursor + 46, count: nameLength)
            guard let name = String(data: nameData, encoding: .utf8),
                  !name.contains(".."), !name.hasPrefix("/") else {
                throw NumbersWorkbookBackup.BackupError.invalidWorkbook
            }
            cursor += 46 + nameLength + extraLength + commentLength
            guard size <= 20_000_000, totalUncompressed + size <= 80_000_000,
                  try data.uint32(at: localOffset) == 0x04034b50 else {
                throw NumbersWorkbookBackup.BackupError.tooLarge
            }
            let localNameLength = Int(try data.uint16(at: localOffset + 26))
            let localExtraLength = Int(try data.uint16(at: localOffset + 28))
            let compressed = try data.bytes(
                at: localOffset + 30 + localNameLength + localExtraLength,
                count: compressedSize
            )
            let contents: Data
            if method == 0 {
                contents = compressed
            } else if method == 8 {
                contents = try inflate(compressed, size: size)
            } else {
                throw NumbersWorkbookBackup.BackupError.invalidWorkbook
            }
            guard contents.count == size, crc(contents) == checksum,
                  files[name] == nil else {
                throw NumbersWorkbookBackup.BackupError.invalidWorkbook
            }
            files[name] = contents
            totalUncompressed += size
        }
        return files
    }

    private static func crc(_ data: Data) -> UInt32 {
        data.withUnsafeBytes { bytes in
            UInt32(crc32(0, bytes.bindMemory(to: Bytef.self).baseAddress, uInt(bytes.count)))
        }
    }

    private static func inflate(_ input: Data, size: Int) throws -> Data {
        if size == 0 { return Data() }
        var output = Data(count: size)
        var stream = z_stream()
        guard inflateInit2_(&stream, -MAX_WBITS, ZLIB_VERSION,
                            Int32(MemoryLayout<z_stream>.size)) == Z_OK else {
            throw NumbersWorkbookBackup.BackupError.invalidWorkbook
        }
        defer { inflateEnd(&stream) }
        let result: Int32 = input.withUnsafeBytes { source in
            output.withUnsafeMutableBytes { destination in
                stream.next_in = UnsafeMutablePointer(mutating: source.bindMemory(to: Bytef.self).baseAddress)
                stream.avail_in = uInt(source.count)
                stream.next_out = destination.bindMemory(to: Bytef.self).baseAddress
                stream.avail_out = uInt(destination.count)
                return zlib.inflate(&stream, Z_FINISH)
            }
        }
        guard result == Z_STREAM_END, Int(stream.total_out) == size else {
            throw NumbersWorkbookBackup.BackupError.invalidWorkbook
        }
        return output
    }
}

private extension Data {
    mutating func appendLE(_ value: UInt16) {
        append(UInt8(truncatingIfNeeded: value))
        append(UInt8(truncatingIfNeeded: value >> 8))
    }

    mutating func appendLE(_ value: UInt32) {
        append(UInt8(truncatingIfNeeded: value))
        append(UInt8(truncatingIfNeeded: value >> 8))
        append(UInt8(truncatingIfNeeded: value >> 16))
        append(UInt8(truncatingIfNeeded: value >> 24))
    }

    func uint16(at offset: Int) throws -> UInt16 {
        guard offset >= 0, offset <= count - 2 else {
            throw NumbersWorkbookBackup.BackupError.invalidWorkbook
        }
        return UInt16(self[offset]) | UInt16(self[offset + 1]) << 8
    }

    func uint32(at offset: Int) throws -> UInt32 {
        guard offset >= 0, offset <= count - 4 else {
            throw NumbersWorkbookBackup.BackupError.invalidWorkbook
        }
        return UInt32(self[offset]) | UInt32(self[offset + 1]) << 8 |
            UInt32(self[offset + 2]) << 16 | UInt32(self[offset + 3]) << 24
    }

    func bytes(at offset: Int, count length: Int) throws -> Data {
        guard offset >= 0, length >= 0, offset <= count,
              length <= count - offset else {
            throw NumbersWorkbookBackup.BackupError.invalidWorkbook
        }
        return subdata(in: offset..<(offset + length))
    }
}

private enum WorkbookXML {
    static func sheets(_ data: Data) throws -> [String: String] {
        let parser = Collector(mode: .workbook)
        try parser.parse(data)
        return parser.sheetIDs
    }

    static func relationships(_ data: Data) throws -> [String: String] {
        let parser = Collector(mode: .relationships)
        try parser.parse(data)
        return parser.paths
    }

    static func sharedStrings(_ data: Data) throws -> [String] {
        let parser = Collector(mode: .sharedStrings)
        try parser.parse(data)
        return parser.strings
    }

    static func rows(_ data: Data, sharedStrings: [String]) throws -> [[String]] {
        let parser = Collector(mode: .worksheet)
        parser.strings = sharedStrings
        try parser.parse(data)
        return parser.rows
    }

    private final class Collector: NSObject, XMLParserDelegate {
        enum Mode { case workbook, relationships, sharedStrings, worksheet }
        let mode: Mode
        var sheetIDs: [String: String] = [:]
        var paths: [String: String] = [:]
        var strings: [String] = []
        var rows: [[String]] = []
        private var currentString = ""
        private var currentRow: [Int: String] = [:]
        private var currentColumn: Int?
        private var currentType = ""
        private var currentValue = ""
        private var currentElement = ""
        private var rowNumber = 0

        init(mode: Mode) { self.mode = mode }

        func parse(_ data: Data) throws {
            let parser = XMLParser(data: data)
            parser.delegate = self
            parser.shouldResolveExternalEntities = false
            guard parser.parse() else {
                throw parser.parserError ?? NumbersWorkbookBackup.BackupError.invalidWorkbook
            }
        }

        func parser(_ parser: XMLParser, didStartElement elementName: String,
                    namespaceURI: String?, qualifiedName qName: String?,
                    attributes: [String: String]) {
            let element = elementName.components(separatedBy: ":").last ?? elementName
            switch mode {
            case .workbook where element == "sheet":
                if let name = attributes["name"],
                   let id = attributes["r:id"] ?? attributes["id"] {
                    sheetIDs[name] = id
                }
            case .relationships where element == "Relationship":
                if let id = attributes["Id"], let target = attributes["Target"] {
                    let path = target.hasPrefix("/")
                        ? String(target.dropFirst())
                        : "xl/" + target
                    if !path.contains("..") { paths[id] = path }
                }
            case .sharedStrings:
                if element == "si" { currentString = "" }
                if element == "t" { currentElement = "t" }
            case .worksheet:
                if element == "row" {
                    currentRow = [:]
                    rowNumber = Int(attributes["r"] ?? "") ?? (rows.count + 1)
                } else if element == "c" {
                    currentColumn = Self.column(attributes["r"] ?? "")
                    currentType = attributes["t"] ?? ""
                    currentValue = ""
                } else if element == "v" || element == "t" {
                    currentElement = element
                }
            default:
                break
            }
        }

        func parser(_ parser: XMLParser, foundCharacters string: String) {
            switch mode {
            case .sharedStrings where currentElement == "t":
                currentString += string
            case .worksheet where currentElement == "v" || currentElement == "t":
                currentValue += string
            default:
                break
            }
        }

        func parser(_ parser: XMLParser, didEndElement elementName: String,
                    namespaceURI: String?, qualifiedName qName: String?) {
            let element = elementName.components(separatedBy: ":").last ?? elementName
            switch mode {
            case .sharedStrings:
                if element == "t" { currentElement = "" }
                if element == "si" { strings.append(currentString) }
            case .worksheet:
                if element == "v" || element == "t" { currentElement = "" }
                if element == "c", let column = currentColumn, column < 100 {
                    if currentType == "s", let index = Int(currentValue),
                       strings.indices.contains(index) {
                        currentRow[column] = strings[index]
                    } else {
                        currentRow[column] = currentValue
                    }
                    currentColumn = nil
                }
                if element == "row", rowNumber > 0, rowNumber < 100_000 {
                    while rows.count < rowNumber - 1 { rows.append([]) }
                    let maxColumn = currentRow.keys.max() ?? -1
                    var row = Array(repeating: "", count: maxColumn + 1)
                    for (column, value) in currentRow { row[column] = value }
                    rows.append(row)
                }
            default:
                break
            }
        }

        private static func column(_ reference: String) -> Int? {
            var value = 0
            var sawLetter = false
            for character in reference.uppercased().unicodeScalars {
                guard character.value >= 65 && character.value <= 90 else { break }
                value = value * 26 + Int(character.value - 64)
                sawLetter = true
            }
            return sawLetter ? value - 1 : nil
        }
    }
}
