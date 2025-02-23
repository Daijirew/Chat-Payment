import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> createBooking({
    required String sitterId,
    required List<DateTime> dates,
    required double totalPrice,
    String? notes,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Please login before making a booking');
      }

      // Create the booking document
      DocumentReference bookingRef =
          await _firestore.collection('bookings').add({
        'userId': currentUser.uid,
        'sitterId': sitterId,
        'dates': dates.map((date) => Timestamp.fromDate(date)).toList(),
        'status': 'pending',
        'totalPrice': totalPrice,
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return bookingRef.id;
    } catch (e) {
      throw Exception('Unable to create booking: $e');
    }
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Unable to update booking status: $e');
    }
  }
}

class BookingScreen extends StatefulWidget {
  final String sitterId;
  final List<DateTime> selectedDates;
  final String sitterName;
  final double pricePerDay;

  const BookingScreen({
    Key? key,
    required this.sitterId,
    required this.selectedDates,
    required this.sitterName,
    required this.pricePerDay,
  }) : super(key: key);

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final TextEditingController _notesController = TextEditingController();
  final BookingService _bookingService = BookingService();
  bool _isLoading = false;
  final DateFormat _dateFormatter = DateFormat('dd MMM yyyy', 'en_US');

  double get totalPrice => widget.selectedDates.length * widget.pricePerDay;

  Future<void> _confirmBooking() async {
    try {
      setState(() => _isLoading = true);

      String bookingId = await _bookingService.createBooking(
        sitterId: widget.sitterId,
        dates: widget.selectedDates,
        totalPrice: totalPrice,
        notes: _notesController.text.trim(),
      );

      setState(() => _isLoading = false);

      // Show success dialog
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Booking Successful'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Booking ID: $bookingId'),
              const SizedBox(height: 8),
              const Text('Please wait for the sitter to confirm your booking'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Booking'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking Details',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Sitter:', widget.sitterName),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Selected Dates:',
                      widget.selectedDates.length > 1
                          ? '${_dateFormatter.format(widget.selectedDates.first)} - ${_dateFormatter.format(widget.selectedDates.last)}'
                          : _dateFormatter.format(widget.selectedDates.first),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow('Number of Days:',
                        '${widget.selectedDates.length} days'),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Price per Day:',
                      '${widget.pricePerDay.toStringAsFixed(0)} Baht',
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      'Total Price:',
                      '${totalPrice.toStringAsFixed(0)} Baht',
                      isTotal: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Note to Sitter',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText:
                            'Add additional information or special care instructions for your cat',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _confirmBooking,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Confirm Booking'),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(child: Text('Please login to view your bookings'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: currentUser.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No booking history found'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final booking = snapshot.data!.docs[index];
              final data = booking.data() as Map<String, dynamic>;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(data['sitterId'])
                    .get(),
                builder: (context, sitterSnapshot) {
                  if (!sitterSnapshot.hasData) {
                    return const SizedBox.shrink();
                  }

                  final sitterData =
                      sitterSnapshot.data!.data() as Map<String, dynamic>;
                  final List<Timestamp> dates =
                      List<Timestamp>.from(data['dates']);

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(sitterData['photo']),
                        onBackgroundImageError: (_, __) =>
                            const Icon(Icons.person),
                      ),
                      title: Text(sitterData['name']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date: ${DateFormat('dd/MM/yyyy').format(dates.first.toDate())} - ${DateFormat('dd/MM/yyyy').format(dates.last.toDate())}',
                          ),
                          Text('Status: ${_getStatusText(data['status'])}'),
                        ],
                      ),
                      trailing: _getStatusIcon(data['status']),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'cancelled':
        return 'Cancelled';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }

  Widget _getStatusIcon(String status) {
    IconData iconData;
    Color color;

    switch (status) {
      case 'pending':
        iconData = Icons.access_time;
        color = Colors.orange;
        break;
      case 'confirmed':
        iconData = Icons.check_circle;
        color = Colors.green;
        break;
      case 'cancelled':
        iconData = Icons.cancel;
        color = Colors.red;
        break;
      case 'completed':
        iconData = Icons.done_all;
        color = Colors.blue;
        break;
      default:
        iconData = Icons.help;
        color = Colors.grey;
    }

    return Icon(iconData, color: color);
  }
}
