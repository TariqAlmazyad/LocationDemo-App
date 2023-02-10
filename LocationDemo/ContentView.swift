//
//  ContentView.swift
//  LocationDemo
//
//  Created by AA on 2/10/23.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        VStack{
            Button {
                locationManager.requestLocation()
            } label: {
                Label("Access Location", systemImage: "location.fill")
                    .font(.title)
            }
            Circle()
                .frame(width: 40, height: 40)
                .foregroundColor(locationManager.isAuthorized ? .green : .red)
        }
        .onChange(of: locationManager.locationStatus) { status in
            if status == .restricted || status == .denied {
                locationManager.isShowingAlert.toggle()
            }
        }
        
        .alert("Location Access Denied", isPresented: $locationManager.isShowingAlert) {
            Button {
                if let appSettings = URL(string: UIApplication.openSettingsURLString + Bundle.main.bundleIdentifier!) {
                  if UIApplication.shared.canOpenURL(appSettings) {
                    DispatchQueue.main.async {
                        UIApplication.shared.open(appSettings)
                    }
                  }
                }
            } label: {
                Text("Go To Setting")
            }
            
            Button(role: .destructive) {
                
            } label: {
                Text("Ignore")
            }

        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.dark)
    }
}



import SwiftUI
import CoreLocation
import MapKit
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var locationStatus: CLAuthorizationStatus?
    @Published var userLocation: CLLocation?
    @Published var isAuthorized: Bool = false
    @Published var isShowingAlert: Bool = false
    @Published var region: MKCoordinateRegion = .init(center: CLLocationCoordinate2D(latitude: 25.869619,
                                                                                     longitude: 43.498501),
                                                      span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
    override init() {
        super.init()
        locationManager.delegate = self
    }
    
    func requestLocation(){
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    var statusString: String {
        guard let status = locationStatus else {
            return "unknown"
        }
        
        print("DEBUG: status \(status)")
        switch status {
        case .notDetermined:
            isAuthorized = false
            return "notDetermined"
        case .authorizedWhenInUse:
            if let userLocation{
                region = MKCoordinateRegion(center: userLocation.coordinate,
                                            span: .init(latitudeDelta: 0.05, longitudeDelta: 0.05))
            }
            return "authorizedWhenInUse"
        case .authorizedAlways:
            if let userLocation{
                region = MKCoordinateRegion(center: userLocation.coordinate,
                                            span: .init(latitudeDelta: 0.05, longitudeDelta: 0.05))
            }
            self.isAuthorized = true
            return "authorizedAlways"
        case .restricted:
            isAuthorized = false
            return "restricted"
        case .denied:
            isAuthorized = false
            return "denied"
        default:
            return "unknown"
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationStatus = status
        print(statusString)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationManager.startUpdatingLocation()
        guard let location = locations.last else { return }
        userLocation = location
        
        if let userLocation {
            region.center = userLocation.coordinate
        }
        
        locationManager.stopUpdatingLocation()
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("DEBUG: error while getting location")
    }
}
