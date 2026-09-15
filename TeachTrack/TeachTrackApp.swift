//
//  TeachTrackApp.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/9/26.
//

import SwiftUI
import SwiftData

@main
struct TeachTrackApp: App {
    

    var body: some Scene {
        WindowGroup {
            
                MainTabView()
                    
        }
        .modelContainer(for: [
            Organization.self,
            Group.self,
            Student.self,
            Contact.self,
            Enrollment.self,
            ScheduleRule.self,
            Lesson.self,
            Attendance.self,
            Transaction.self,
            StudentNote.self,
            LessonNote.self
        ])
    }
}
