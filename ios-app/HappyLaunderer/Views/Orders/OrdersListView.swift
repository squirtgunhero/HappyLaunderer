//
//  OrdersListView.swift
//  HappyLaunderer
//
//  List view showing all orders
//

import SwiftUI

struct OrdersListView: View {
    @EnvironmentObject var orderManager: OrderManager
    @State private var selectedFilter: OrderFilter = .all
    
    enum OrderFilter: String, CaseIterable {
        case all = "All"
        case active = "Active"
        case completed = "Completed"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter picker
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(OrderFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Orders list
                if orderManager.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredOrders.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "tray")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No orders found")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        Text("Your orders will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 15) {
                            ForEach(filteredOrders) { order in
                                NavigationLink(destination: OrderDetailView(order: order)) {
                                    OrderRowView(order: order)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Orders")
            .refreshable {
                try? await orderManager.fetchOrders()
            }
        }
        .task {
            try? await orderManager.fetchOrders()
        }
    }
    
    private var filteredOrders: [Order] {
        switch selectedFilter {
        case .all:
            return orderManager.orders
        case .active:
            return orderManager.orders.filter { $0.status.isActive }
        case .completed:
            return orderManager.orders.filter { $0.status.isCompleted }
        }
    }
}

#Preview {
    OrdersListView()
        .environmentObject(OrderManager.shared)
}

