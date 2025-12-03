import SwiftUI

struct ProfileView: View {
    @Environment(\.diContainer) private var diContainer
    @EnvironmentObject var subscriptionService: SubscriptionService
    @EnvironmentObject var authService: AuthenticationService
    @ObservedObject var firestoreService: FirestoreService = DIContainer.shared.firestoreService
    
    @State private var showLogoutAlert = false
    @State private var isEditMode = false
    
    // Edit fields
    @State private var editFirstName = ""
    @State private var editLastName = ""
    @State private var editDateOfBirth = Date()
    @State private var editHeightFeet = 5
    @State private var editHeightInches = 8
    @State private var editWeightPounds = ""
    @State private var editExperience = "Intermediate"
    @State private var editGoals: Set<String> = []
    @State private var isSaving = false
    
    let goalOptions = ["Build Muscle", "Lose Weight", "Get Toned", "General Fitness", "Athletic Performance"]
    let experienceLevels = ["Beginner", "Intermediate", "Advanced"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.ZP.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Premium Header
                        ProfileHeader(
                            userProfile: firestoreService.currentUserProfile,
                            isEditMode: $isEditMode,
                            onEdit: startEditing,
                            onSave: saveProfile,
                            isSaving: isSaving
                        )
                        
                        if isEditMode {
                            // Edit Mode UI
                            EditProfileForm(
                                firstName: $editFirstName,
                                lastName: $editLastName,
                                dateOfBirth: $editDateOfBirth,
                                heightFeet: $editHeightFeet,
                                heightInches: $editHeightInches,
                                weightPounds: $editWeightPounds,
                                experience: $editExperience,
                                selectedGoals: $editGoals,
                                goalOptions: goalOptions,
                                experienceLevels: experienceLevels
                            )
                        } else {
                            // Display Mode UI
                            ProfileDetailsDisplay(userProfile: firestoreService.currentUserProfile)
                            
                            // Stats Grid
                            StatsGrid()
                            
                            // Membership Card
                            MembershipCard()
                            
                            // Settings List
                            SettingsList()
                        }
                        
                        // Logout
                        LogoutButton(showLogoutAlert: $showLogoutAlert)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
            }
            .navigationBarHidden(true)
            .alert("Log Out", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Log Out", role: .destructive) {
                    do {
                        try authService.signOut()
                    } catch {
                        print("Error signing out: \(error)")
                    }
                }
            } message: {
                Text("Are you sure you want to log out?")
            }
        }
    }
    
    private func startEditing() {
        guard let profile = firestoreService.currentUserProfile else { return }
        
        editFirstName = profile.firstName ?? ""
        editLastName = profile.lastName ?? ""
        editDateOfBirth = profile.dateOfBirth ?? Date()
        editHeightFeet = profile.heightFeet ?? 5
        editHeightInches = profile.heightInches ?? 8
        editWeightPounds = "\(profile.weightPounds ?? 0)"
        editExperience = profile.experienceLevel ?? "Intermediate"
        editGoals = Set(profile.goals ?? [])
        
        withAnimation {
            isEditMode = true
        }
    }
    
    private func saveProfile() {
        guard let userId = authService.currentUserId else { return }
        
        isSaving = true
        
        Task {
            do {
                let weight = Int(editWeightPounds) ?? 0
                try await firestoreService.updateUserProfile(
                    userId: userId,
                    firstName: editFirstName,
                    lastName: editLastName,
                    dateOfBirth: editDateOfBirth,
                    heightFeet: editHeightFeet,
                    heightInches: editHeightInches,
                    weightPounds: weight,
                    experienceLevel: editExperience,
                    goals: Array(editGoals)
                )
                
                // Reload profile
                await firestoreService.loadUserData(userId: userId)
                
                await MainActor.run {
                    withAnimation {
                        isEditMode = false
                    }
                    isSaving = false
                }
            } catch {
                print("Error saving profile: \(error)")
                await MainActor.run {
                    isSaving = false
                }
            }
        }
    }
}

// MARK: - Profile Header
struct ProfileHeader: View {
    let userProfile: FirestoreUserProfile?
    @Binding var isEditMode: Bool
    let onEdit: () -> Void
    let onSave: () -> Void
    let isSaving: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.ZP.cardHover)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Text(userProfile?.initials ?? "??")
                            .font(.ZP.largeTitle)
                            .foregroundStyle(Color.ZP.textPrimary)
                    )
                
                Image(systemName: "checkmark.seal.fill")
                    .font(.title2)
                    .foregroundStyle(Color.ZP.primary)
                    .background(Circle().fill(Color.black).padding(2))
            }
            
            VStack(spacing: 4) {
                Text(userProfile?.fullName ?? "Unknown User")
                    .font(.ZP.title1)
                    .foregroundStyle(Color.ZP.textPrimary)
                
                if let email = userProfile?.email {
                    Text(email)
                        .font(.ZP.subheadline)
                        .foregroundStyle(Color.ZP.textSecondary)
                }
            }
            
            // Edit/Save Button
            if isEditMode {
                HStack(spacing: 12) {
                    Button(action: {
                        withAnimation {
                            isEditMode = false
                        }
                    }) {
                        Text("Cancel")
                            .font(.ZP.subheadline)
                            .foregroundStyle(Color.ZP.textPrimary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color.ZP.card)
                            .cornerRadius(20)
                    }
                    
                    Button(action: onSave) {
                        ZStack {
                            if isSaving {
                                ProgressView()
                                    .tint(.black)
                            } else {
                                Text("Save Changes")
                                    .font(.ZP.subheadline)
                                    .fontWeight(.semibold)
                            }
                        }
                        .foregroundStyle(Color.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.ZP.primary)
                        .cornerRadius(20)
                    }
                    .disabled(isSaving)
                }
            } else {
                Button(action: onEdit) {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                            .font(.caption)
                        Text("Edit Profile")
                            .font(.ZP.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(Color.ZP.primary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.ZP.card)
                    .cornerRadius(20)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

// MARK: - Profile Details Display
struct ProfileDetailsDisplay: View {
    let userProfile: FirestoreUserProfile?
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Personal Information")
                .font(.ZP.headline)
                .foregroundStyle(Color.ZP.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                InfoRow(label: "Height", value: userProfile?.heightFormatted ?? "Not set")
                InfoRow(label: "Weight", value: userProfile?.weightFormatted ?? "Not set")
                InfoRow(label: "Experience", value: userProfile?.experienceLevel ?? "Not set")
                
                if let dob = userProfile?.dateOfBirth {
                    InfoRow(label: "Date of Birth", value: dob.formatted(date: .long, time: .omitted))
                }
                
                if let goals = userProfile?.goals, !goals.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Goals")
                            .font(.ZP.subheadline)
                            .foregroundStyle(Color.ZP.textSecondary)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(goals, id: \.self) { goal in
                                Text(goal)
                                    .font(.ZP.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.ZP.primary.opacity(0.2))
                                    .foregroundStyle(Color.ZP.primary)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.ZP.card)
                    .cornerRadius(12)
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Edit Profile Form
struct EditProfileForm: View {
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var dateOfBirth: Date
    @Binding var heightFeet: Int
    @Binding var heightInches: Int
    @Binding var weightPounds: String
    @Binding var experience: String
    @Binding var selectedGoals: Set<String>
    let goalOptions: [String]
    let experienceLevels: [String]
    
    var body: some View {
        VStack(spacing: 20) {
            // Name
            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(.ZP.headline)
                    .foregroundStyle(Color.ZP.textSecondary)
                
                HStack(spacing: 12) {
                    TextField("First Name", text: $firstName)
                        .font(.ZP.body)
                        .padding()
                        .background(Color.ZP.card)
                        .cornerRadius(12)
                    
                    TextField("Last Name", text: $lastName)
                        .font(.ZP.body)
                        .padding()
                        .background(Color.ZP.card)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)
            
            // Date of Birth
            VStack(alignment: .leading, spacing: 8) {
                Text("Date of Birth")
                    .font(.ZP.headline)
                    .foregroundStyle(Color.ZP.textSecondary)
                
                DatePicker("", selection: $dateOfBirth, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .colorScheme(.dark)
                    .padding()
                    .background(Color.ZP.card)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            
            // Height
            VStack(alignment: .leading, spacing: 8) {
                Text("Height")
                    .font(.ZP.headline)
                    .foregroundStyle(Color.ZP.textSecondary)
                
                HStack(spacing: 16) {
                    Picker("Feet", selection: $heightFeet) {
                        ForEach(3..<8) { feet in
                            Text("\(feet) ft").tag(feet)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding()
                    .background(Color.ZP.card)
                    .cornerRadius(12)
                    
                    Picker("Inches", selection: $heightInches) {
                        ForEach(0..<12) { inches in
                            Text("\(inches) in").tag(inches)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding()
                    .background(Color.ZP.card)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)
            
            // Weight
            VStack(alignment: .leading, spacing: 8) {
                Text("Weight")
                    .font(.ZP.headline)
                    .foregroundStyle(Color.ZP.textSecondary)
                
                HStack {
                    TextField("Weight", text: $weightPounds)
                        .keyboardType(.numberPad)
                        .font(.ZP.body)
                        .padding()
                        .background(Color.ZP.card)
                        .cornerRadius(12)
                    
                    Text("lbs")
                        .font(.ZP.body)
                        .foregroundStyle(Color.ZP.textSecondary)
                }
            }
            .padding(.horizontal, 20)
            
            // Experience
            VStack(alignment: .leading, spacing: 8) {
                Text("Experience Level")
                    .font(.ZP.headline)
                    .foregroundStyle(Color.ZP.textSecondary)
                
                Picker("Experience", selection: $experience) {
                    ForEach(experienceLevels, id: \.self) { level in
                        Text(level).tag(level)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal, 20)
            
            // Goals
            VStack(alignment: .leading, spacing: 8) {
                Text("Goals")
                    .font(.ZP.headline)
                    .foregroundStyle(Color.ZP.textSecondary)
                
                ForEach(goalOptions, id: \.self) { goal in
                    Button(action: {
                        if selectedGoals.contains(goal) {
                            selectedGoals.remove(goal)
                        } else {
                            selectedGoals.insert(goal)
                        }
                    }) {
                        HStack {
                            Text(goal)
                                .font(.ZP.body)
                                .foregroundStyle(Color.ZP.textPrimary)
                            Spacer()
                            if selectedGoals.contains(goal) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.ZP.primary)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundStyle(Color.ZP.textSecondary)
                            }
                        }
                        .padding()
                        .background(selectedGoals.contains(goal) ? Color.ZP.cardHover : Color.ZP.card)
                        .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.ZP.subheadline)
                .foregroundStyle(Color.ZP.textSecondary)
            Spacer()
            Text(value)
                .font(.ZP.body)
                .foregroundStyle(Color.ZP.textPrimary)
        }
        .padding()
        .background(Color.ZP.card)
        .cornerRadius(12)
    }
}

// MARK: - Stats Grid
struct StatsGrid: View {
    var body: some View {
        HStack(spacing: 16) {
            StatCard(title: "Workouts", value: "0", unit: "", icon: "figure.run")
            StatCard(title: "Calories", value: "0", unit: "", icon: "flame.fill")
            StatCard(title: "Hours", value: "0", unit: "", icon: "clock.fill")
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Membership Card
struct MembershipCard: View {
    @EnvironmentObject var subscriptionService: SubscriptionService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Membership")
                    .font(.ZP.headline)
                    .foregroundStyle(Color.ZP.textSecondary)
                Spacer()
                if subscriptionService.isPremium {
                    Text("PRO")
                        .font(.ZP.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.ZP.primary)
                        .foregroundStyle(Color.black)
                        .cornerRadius(8)
                }
            }
            
            Text(subscriptionService.isPremium ? "Premium Access" : "Free Plan")
                .font(.ZP.title2)
                .foregroundStyle(Color.ZP.textPrimary)
            
            if !subscriptionService.isPremium {
                Button(action: {}) {
                    Text("Upgrade to Premium")
                        .font(.ZP.headline)
                        .foregroundStyle(Color.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.ZP.primary)
                        .cornerRadius(16)
                }
            }
        }
        .padding(24)
        .background(Color.ZP.card)
        .cornerRadius(24)
        .padding(.horizontal, 20)
    }
}

// MARK: - Settings List
struct SettingsList: View {
    var body: some View {
        VStack(spacing: 1) {
            SettingsItem(icon: "bell.fill", title: "Notifications")
            SettingsItem(icon: "lock.fill", title: "Privacy")
            SettingsItem(icon: "gear", title: "General")
            SettingsItem(icon: "questionmark.circle.fill", title: "Support")
        }
        .background(Color.ZP.card)
        .cornerRadius(20)
        .padding(.horizontal, 20)
    }
}

struct SettingsItem: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Color.ZP.textSecondary)
                .frame(width: 24)
            
            Text(title)
                .font(.ZP.body)
                .foregroundStyle(Color.ZP.textPrimary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.ZP.textSecondary)
        }
        .padding(20)
        .background(Color.ZP.card)
    }
}

// MARK: - Logout Button
struct LogoutButton: View {
    @Binding var showLogoutAlert: Bool
    
    var body: some View {
        Button(action: { showLogoutAlert = true }) {
            Text("Log Out")
                .font(.ZP.headline)
                .foregroundStyle(Color.ZP.error)
                .padding()
        }
    }
}

// MARK: - Flow Layout Helper
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrangeRows(proposal: proposal, subviews: subviews)
        let height = rows.reduce(0) { $0 + $1.height + spacing } - spacing
        return CGSize(width: proposal.width ?? 0, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrangeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        
        for row in rows {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: .unspecified)
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }
    
    private func arrangeRows(proposal: ProposedViewSize, subviews: Subviews) -> [(indices: [Int], height: CGFloat)] {
        var rows: [(indices: [Int], height: CGFloat)] = []
        var currentRow: [Int] = []
        var currentWidth: CGFloat = 0
        var currentHeight: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity
        
        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentWidth + size.width + (currentRow.isEmpty ? 0 : spacing) > maxWidth {
                rows.append((currentRow, currentHeight))
                currentRow = [index]
                currentWidth = size.width
                currentHeight = size.height
            } else {
                currentRow.append(index)
                currentWidth += size.width + (currentRow.count > 1 ? spacing : 0)
                currentHeight = max(currentHeight, size.height)
            }
        }
        
        if !currentRow.isEmpty {
            rows.append((currentRow, currentHeight))
        }
        
        return rows
    }
}
