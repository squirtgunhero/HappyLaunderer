//
//  OrderDetailView.swift
//  HappyLaunderer
//
//  Detailed view of an order with tracking
//

import SwiftUI
import MapKit

struct OrderDetailView: View {
    @EnvironmentObject var orderManager: OrderManager
    @State var order: Order
    @State private var statusHistory: [OrderStatusHistory] = []
    @State private var showCancelConfirmation = false
    @State private var isRefreshing = false
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Status card
                VStack(spacing: 15) {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(statusColor.opacity(0.2))
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: order.status.systemImage)
                                .font(.title)
                                .foregroundColor(statusColor)
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text(order.status.displayName)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Order #\(order.id.prefix(8))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    // Show map if driver is en route
                    if order.status == .outForDelivery,
                       let driverLocation = order.driverLocation {
                        Map(coordinateRegion: $region, annotationItems: [driverLocation]) { location in
                            MapAnnotation(coordinate: CLLocationCoordinate2D(
                                latitude: location.latitude,
                                longitude: location.longitude
                            )) {
                                VStack {
                                    Image(systemName: "car.fill")
                                        .foregroundColor(.blue)
                                        .font(.title2)
                                    Text("Driver")
                                        .font(.caption)
                                        .padding(4)
                                        .background(Color.white)
                                        .cornerRadius(4)
                                }
                            }
                        }
                        .frame(height: 200)
                        .cornerRadius(12)
                        .onAppear {
                            region.center = CLLocationCoordinate2D(
                                latitude: driverLocation.latitude,
                                longitude: driverLocation.longitude
                            )
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(.systemBackground))
                        .shadow(color: .gray.opacity(0.3), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal)
                
                // Order details
                VStack(alignment: .leading, spacing: 15) {
                    Text("Order Details")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    DetailRow(title: "Service Type", value: order.serviceType.displayName)
                    DetailRow(title: "Scheduled Time", value: order.scheduledTime.formatted(date: .long, time: .shortened))
                    DetailRow(title: "Items", value: "\(order.itemCount)")
                    DetailRow(title: "Price", value: "$\(String(format: "%.2f", order.price))")
                    
                    if let notes = order.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Notes")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            Text(notes)
                                .font(.body)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(.systemBackground))
                        .shadow(color: .gray.opacity(0.3), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal)
                
                // Addresses
                VStack(alignment: .leading, spacing: 15) {
                    Text("Addresses")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    AddressCard(title: "Pickup", address: order.pickupAddress)
                    AddressCard(title: "Delivery", address: order.deliveryAddress)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(.systemBackground))
                        .shadow(color: .gray.opacity(0.3), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal)
                
                // Status history
                if !statusHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Status History")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        ForEach(statusHistory) { history in
                            HStack(alignment: .top, spacing: 15) {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 10, height: 10)
                                    .padding(.top, 5)
                                
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(history.newStatus.displayName)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    Text(history.createdAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    if let notes = history.notes {
                                        Text(notes)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(.systemBackground))
                            .shadow(color: .gray.opacity(0.3), radius: 10, x: 0, y: 5)
                    )
                    .padding(.horizontal)
                }
                
                // Cancel button
                if order.status.isActive && order.status != .outForDelivery {
                    Button(action: {
                        showCancelConfirmation = true
                    }) {
                        Text("Cancel Order")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                
                Spacer(minLength: 30)
            }
            .padding(.top)
        }
        .navigationTitle("Order Details")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await refreshOrder()
        }
        .confirmationDialog("Cancel Order", isPresented: $showCancelConfirmation) {
            Button("Cancel Order", role: .destructive) {
                Task {
                    try? await orderManager.cancelOrder(orderId: order.id)
                }
            }
            Button("Keep Order", role: .cancel) {}
        } message: {
            Text("Are you sure you want to cancel this order?")
        }
        .task {
            await refreshOrder()
            
            // Start real-time updates if order is active
            // The task will automatically be cancelled when the view disappears
            if order.status.isActive {
                await withTaskCancellationHandler {
                    // Start polling in a child task
                    let pollingTask = orderManager.startRealTimeUpdates(for: order.id)
                    
                    // Wait for the polling task to complete or be cancelled
                    await pollingTask.value
                } onCancel: {
                    // Stop polling when view disappears
                    orderManager.stopRealTimeUpdates(for: order.id)
                }
            }
        }
        .onDisappear {
            // Extra safety: ensure polling stops when view disappears
            orderManager.stopRealTimeUpdates(for: order.id)
        }
    }
    
    private var statusColor: Color {
        switch order.status {
        case .pending:
            return .orange
        case .pickedUp, .inLaundry:
            return .blue
        case .ready:
            return .green
        case .outForDelivery:
            return .purple
        case .completed:
            return .green
        case .cancelled:
            return .red
        }
    }
    
    private func refreshOrder() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        
        do {
            let (updatedOrder, history) = try await orderManager.fetchOrderDetails(orderId: order.id)
            order = updatedOrder
            statusHistory = history
        } catch {
            print("Failed to refresh order: \(error)")
        }
        
        isRefreshing = false
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
        }
    }
}

struct AddressCard: View {
    let title: String
    let address: Address
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Text(address.formattedAddress)
                .font(.body)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}

// Make DriverLocation identifiable for MapKit
extension DriverLocation: Identifiable {
    var id: String {
        "\(latitude)-\(longitude)-\(timestamp)"
    }
}

#Preview {
    NavigationView {
        OrderDetailView(order: Order(
            id: "1",
            userId: "1",
            pickupAddress: Address(street: "123 Main St", city: "San Francisco", state: "CA", zipCode: "94102", latitude: nil, longitude: nil),
            deliveryAddress: Address(street: "456 Oak Ave", city: "San Francisco", state: "CA", zipCode: "94103", latitude: nil, longitude: nil),
            scheduledTime: Date(),
            status: .outForDelivery,
            serviceType: .express,
            itemCount: 5,
            price: 40.00,
            driverId: "driver1",
            driverLocation: DriverLocation(latitude: 37.7749, longitude: -122.4194, timestamp: Date()),
            notes: "Please handle with care",
            createdAt: Date(),
            updatedAt: Date()
        ))
    }
    .environmentObject(OrderManager.shared)
}

