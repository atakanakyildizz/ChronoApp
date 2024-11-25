import SwiftUI
import EventKit

struct ContentView: View {
    @State private var timeRemaining = 1500  // Default time: 25 minutes (in seconds)
    @State private var goalSeconds = 1500  // Default time: 25 minutes (in seconds)
    @State private var isRunning = false
    @State private var timer: Timer? = nil
    @State private var dailyWorkTime = 0  // Daily work time (in seconds)
    @State private var isCalendarAuthorized = false  // Calendar access permission status
    @State private var studyEvent: EKEvent? = nil  // Study event in the calendar
    @State private var newStartTime = 25  // New start time (in minutes)
    @State private var showingResetSheet = false  // For new start time input
    @State private var progressBarColor: Color = .green  // Progress bar color
    let eventStore = EKEventStore()

    var body: some View {
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)

            ScrollView {
                VStack {
                    Spacer()

                    // Title
                    Text("Timer")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                        .bold()
                        .padding(.top, 5)

                    // Time Display
                    Text(formatTime(timeRemaining))
                        .font(.system(size: 50))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .onTapGesture {
                            // When tapped on the time, an alert opens to change the time
                            showingResetSheet = true
                        }

                    // Progress Bar
                    ProgressView(value: Double(goalSeconds - timeRemaining), total: Double(goalSeconds))
                        .progressViewStyle(LinearProgressViewStyle())
                        .padding(.top, 5)
                        .frame(height: 20)
                        .accentColor(progressBarColor) // Set the progress bar color here

                    // Start/Stop and Reset Buttons
                    HStack {
                        Button(action: { self.toggleTimer() }) {
                            Text(isRunning ? "Stop" : "Start")
                                .font(.system(size: 20))
                                .fontWeight(.bold)
                                .padding(5)
                                .frame(width: 100, height: 40)
                                .background(isRunning ? Color.red : Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        
                        Button(action: { self.resetTimer() }) {
                            Text("Reset")
                                .font(.system(size: 20))
                                .fontWeight(.bold)
                                .padding(5)
                                .frame(width: 100, height: 40)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }

                        Button(action: { self.saveToCalendar() }) {
                            Text("Save")
                                .font(.system(size: 20))
                                .fontWeight(.bold)
                                .padding(5)
                                .frame(width: 100, height: 40)
                                .background(Color.yellow)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.top, 10)

                    // Daily Work Time
                    HStack {
                        Text("Daily Work Time: \(formatDailyWorkTime(dailyWorkTime))")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                        
                        Button(action: { self.resetDailyWorkTime() }) {
                            Text("Reset")
                                .font(.system(size: 18))
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.top, 10)

                    Spacer()
                }
                .padding()
            }
            .frame(maxWidth: 400, maxHeight: 600) // Limiting window size
            .sheet(isPresented: $showingResetSheet) {
                VStack {
                    Text("New Start Time")
                        .font(.title)
                        .padding()

                    TextField("Enter start time in minutes", value: $newStartTime, formatter: NumberFormatter())
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    Button("OK") {
                        self.setNewStartTime() // Update the start time
                        self.showingResetSheet = false
                    }
                    .font(.title2)
                    .padding()
                }
                .padding()
            }
        }
        .onAppear {
            checkCalendarPermission()
            resetDailyWorkTime()
        }
    }

    private func toggleTimer() {
        if isRunning {
            // Stop the timer
            timer?.invalidate()
        } else {
            // Start the timer
            startTimer()
        }
        isRunning.toggle()
    }

    private func startTimer() {
        // Start the timer
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1  // Decrease the time by 1 second
                dailyWorkTime += 1  // Increase daily work time by 1 second

                // Change color every 10% of the time
                if timeRemaining % (goalSeconds / 10) == 0 {
                    self.changeProgressBarColor()
                }
            } else {
                // When time runs out, save and stop
                self.saveToCalendar()
                self.timer?.invalidate()
            }
        }

        // Add timer to run loop
        RunLoop.current.add(timer!, forMode: .common)
    }

    private func resetTimer() {
        // Reset time
        timeRemaining = goalSeconds
        // Stop the timer
        isRunning = false
        // Reset progress bar color
        changeProgressBarColor()
        // Invalidate the timer
        timer?.invalidate()
        timer = nil
    }

    private func resetDailyWorkTime() {
        // Reset daily work time
        dailyWorkTime = 0
    }

    private func setNewStartTime() {
        // Apply the new start time from user input
        goalSeconds = newStartTime * 60
        resetTimer()
    }

    private func formatTime(_ time: Int) -> String {
        let minutes = time / 60
        let seconds = time % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func formatDailyWorkTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private func changeProgressBarColor() {
        let percentageRemaining = Double(timeRemaining) / Double(goalSeconds)
        if percentageRemaining > 0.7 {
            progressBarColor = .green
        } else if percentageRemaining > 0.4 {
            progressBarColor = .yellow
        } else {
            progressBarColor = .red
        }
    }

    private func checkCalendarPermission() {
        eventStore.requestAccess(to: .event) { (granted, error) in
            if granted {
                self.isCalendarAuthorized = true
            } else {
                self.isCalendarAuthorized = false
            }
        }
    }

    private func saveToCalendar() {
        guard isCalendarAuthorized else { return }

        // Check the default calendar
        guard let defaultCalendar = eventStore.defaultCalendarForNewEvents else {
            print("Calendar not found or not set.")
            return
        }

        let workTimeFormatted = formatDailyWorkTime(dailyWorkTime) // Format the daily work time

        if let event = studyEvent {
            // Update the existing event
            event.endDate = Date().addingTimeInterval(TimeInterval(dailyWorkTime))
            event.notes = "Today's total work time: \(workTimeFormatted)"
            do {
                try eventStore.save(event, span: .thisEvent)
                print("Event successfully updated.")
            } catch {
                print("Event could not be updated: \(error.localizedDescription)")
            }
        } else {
            // Create a new event
            let newEvent = EKEvent(eventStore: eventStore)
            newEvent.title = "Daily Work Time"
            newEvent.startDate = Date()
            newEvent.endDate = Date().addingTimeInterval(TimeInterval(dailyWorkTime))
            newEvent.notes = "Today's total work time: \(workTimeFormatted)"
            newEvent.calendar = defaultCalendar // Assign the default calendar

            do {
                try eventStore.save(newEvent, span: .thisEvent)
                studyEvent = newEvent
                print("Event successfully saved.")
            } catch {
                print("Event could not be saved to the calendar: \(error.localizedDescription)")
            }
        }
    }

}

