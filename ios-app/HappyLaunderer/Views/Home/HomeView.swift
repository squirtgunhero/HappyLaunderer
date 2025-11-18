//
//  HomeView.swift
//  HappyLaunderer
//
//  Home screen with quick actions
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var orderManager: OrderManager
    @State private var showNewOrderSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome back,")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        Text(authManager.currentUser?.name ?? "User")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    
                    // Quick action card
                    Button(action: {
                        showNewOrderSheet = true
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Request Pickup")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text("Schedule a laundry pickup")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.blue)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color(.systemBackground))
                                .shadow(color: .gray.opacity(0.3), radius: 10, x: 0, y: 5)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                    
                    // Active orders section
                    if !orderManager.activeOrders.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Active Orders")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            ForEach(orderManager.activeOrders) { order in
                                NavigationLink(destination: OrderDetailView(order: order)) {
                                    OrderRowView(order: order)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.top)
                    }
                    
                    // Service types
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Our Services")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        ForEach(ServiceType.allCases, id: \.self) { serviceType in
                            ServiceTypeCard(serviceType: serviceType)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.top)
                    
                    Spacer(minLength: 30)
                }
                .padding(.top)
            }
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                try? await orderManager.fetchOrders()
            }
            .sheet(isPresented: $showNewOrderSheet) {
                NewOrderView()
            }
        }
        .task {
            try? await orderManager.fetchOrders()
        }
    }
}

struct ServiceTypeCard: View {
    let serviceType: ServiceType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(serviceType.displayName)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(serviceType.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("$\(String(format: "%.2f", serviceType.basePrice))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            ForEach(serviceType.features, id: \.self) { feature in
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    
                    Text(feature)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
        )
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthenticationManager.shared)
        .environmentObject(OrderManager.shared)
}

