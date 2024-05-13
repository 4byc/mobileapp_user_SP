import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  final String? username;

  const HomePage({Key? key, this.username}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Smart Parking Management"),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () {
              _confirmSignOut(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 20),
                  Text(
                    "Hello, ${widget.username ?? 'User'}!",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => InputParkingPage(username: widget.username)),
                      );
                    },
                    child: Text("Add Parking Data"),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
            StreamBuilder<List<ParkingModel>>(
              stream: _readData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text("No data found"));
                }
                final parkings = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: parkings.length,
                  itemBuilder: (context, index) {
                    final parking = parkings[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: ExpansionTile(
                        title: Text(parking.vehicleType!.substring(2)),
                        children: [
                          ListTile(
                            title: Text("Driver: ${parking.driverName}"),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Parking Location: ${parking.parkingLocation}"),
                                Text("Timestamp: ${_formatTimestamp(parking.timestamp!)}"),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () {
                                    _editParkingData(parking);
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () {
                                    _deleteData(parking.id!);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Stream<List<ParkingModel>> _readData() {
    final parkingCollection = FirebaseFirestore.instance.collection("parkings");
    return parkingCollection.orderBy("timestamp", descending: true).snapshots().map((querySnapshot) =>
        querySnapshot.docs.map((e) => ParkingModel.fromSnapshot(e)).toList());
  }

  Future<void> _deleteData(String id) async {
    final parkingCollection = FirebaseFirestore.instance.collection("parkings");
    await parkingCollection.doc(id).delete();
    _showToast("Data deleted successfully");
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm Sign Out"),
        content: Text("Are you sure you want to sign out?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, "/login");
              _showToast("Successfully signed out");
            },
            child: Text("Sign Out"),
          ),
        ],
      ),
    );
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    return "${dateTime.day}/${dateTime.month}/${dateTime.year}, ${dateTime.hour}:${dateTime.minute}";
  }

  void _editParkingData(ParkingModel parking) async {
    final updatedParkingData = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditParkingPage(parking: parking)),
    );

    if (updatedParkingData != null) {
      _updateData(updatedParkingData);
    }
  }

  Future<void> _updateData(ParkingModel updatedParkingData) async {
    final parkingCollection = FirebaseFirestore.instance.collection("parkings");
    await parkingCollection.doc(updatedParkingData.id!).update(updatedParkingData.toJson());
    _showToast("Data updated successfully");
  }
}

class InputParkingPage extends StatefulWidget {
  final String? username;

  const InputParkingPage({Key? key, this.username}) : super(key: key);

  @override
  _InputParkingPageState createState() => _InputParkingPageState();
}

class _InputParkingPageState extends State<InputParkingPage> {
  final TextEditingController _driverNameController = TextEditingController();
  String? _selectedVehicleType;

  final List<String> _vehicleTypes = [
    'A_Accord', 'A_Alphard', 'A_Civic', 'A_Crv', 'A_Fortuner', 'A_Innova',
    'B_Avanza', 'B_Camry', 'B_Calya', 'B_City', 'B_Hrv', 'B_Mobilio', 'B_Raize',
    'B_Rocky', 'B_Rush', 'B_Sigra', 'B_Terios', 'B_Vios', 'B_Xenia', 'B_Xpander', 'B_Yaris',
    'C_Agya', 'C_Brio', 'C_Carry', 'C_Grandmax', 'C_Swift',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Parking Data'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedVehicleType,
              onChanged: (newValue) {
                setState(() {
                  _selectedVehicleType = newValue;
                });
              },
              items: _vehicleTypes
                  .map((String value) => DropdownMenuItem<String>(
                value: value,
                child: Text(value.substring(2)),
              ))
                  .toList(),
              decoration: InputDecoration(labelText: 'Vehicle Type'),
            ),
            TextField(
              controller: _driverNameController,
              decoration: InputDecoration(labelText: 'Driver Name'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _saveParkingData();
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveParkingData() {
    final driverName = _driverNameController.text.trim();
    final parkingLocation = _assignParkingLocation(_selectedVehicleType);

    if (_selectedVehicleType != null && driverName.isNotEmpty) {
      final newParkingData = ParkingModel(
        vehicleType: _selectedVehicleType!,
        driverName: driverName,
        parkingLocation: parkingLocation,
        timestamp: Timestamp.now(),
      );

      _createData(newParkingData);
      _showToast("Data added successfully");
      Navigator.pop(context);
    } else {
      _showToast("Please fill in all fields");
    }
  }

  String _assignParkingLocation(String? vehicleType) {
    if (vehicleType != null) {
      final vehicleClass = vehicleType.substring(0, 1);
      switch (vehicleClass) {
        case 'A':
          return 'Lots A, B, and C';
        case 'B':
          return 'Lots D, E, and F';
        case 'C':
          return 'Lots G, H, and I';
        default:
          return 'Parking Lot';
      }
    }
    return 'Parking Lot';
  }

  Future<void> _createData(ParkingModel parkingModel) async {
    final parkingCollection = FirebaseFirestore.instance.collection("parkings");
    await parkingCollection.add(parkingModel.toJson());
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class EditParkingPage extends StatefulWidget {
  final ParkingModel parking;

  const EditParkingPage({Key? key, required this.parking}) : super(key: key);

  @override
  _EditParkingPageState createState() => _EditParkingPageState();
}

class _EditParkingPageState extends State<EditParkingPage> {
  late TextEditingController _driverNameController;

  @override
  void initState() {
    super.initState();
    _driverNameController = TextEditingController(text: widget.parking.driverName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Parking Data'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vehicle Type: ${widget.parking.vehicleType!.substring(2)}'),
            TextField(
              controller: _driverNameController,
              decoration: InputDecoration(labelText: 'Driver Name'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _saveChanges();
              },
              child: Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveChanges() {
    final updatedParkingData = ParkingModel(
      id: widget.parking.id,
      vehicleType: widget.parking.vehicleType,
      driverName: _driverNameController.text,
      parkingLocation: widget.parking.parkingLocation,
      timestamp: widget.parking.timestamp,
    );

    _updateData(updatedParkingData);
    _showToast("Data updated successfully");
    Navigator.pop(context, updatedParkingData);
  }

  Future<void> _updateData(ParkingModel updatedParkingData) async {
    final parkingCollection = FirebaseFirestore.instance.collection("parkings");
    await parkingCollection.doc(updatedParkingData.id!).update(updatedParkingData.toJson());
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _driverNameController.dispose();
    super.dispose();
  }
}

class ParkingModel {
  final String? vehicleType;
  final String? driverName;
  final String? id;
  final Timestamp? timestamp;
  final String? parkingLocation;

  ParkingModel({
    this.id,
    this.vehicleType,
    this.driverName,
    this.timestamp,
    this.parkingLocation,
  });

  static ParkingModel fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    return ParkingModel(
      id: snapshot.id,
      vehicleType: data?['vehicleType'],
      driverName: data?['driverName'],
      timestamp: data?['timestamp'],
      parkingLocation: data?['parkingLocation'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "vehicleType": vehicleType,
      "driverName": driverName,
      "timestamp": timestamp,
      "parkingLocation": parkingLocation,
    };
  }
}

void main() {
  runApp(MaterialApp(
    home: HomePage(),
  ));
}
