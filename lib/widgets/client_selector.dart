import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../config/client_type.dart';
import '../services/client_service.dart';

class ClientSelector extends StatefulWidget {
  final Function(ClientType)? onClientChanged;

  const ClientSelector({super.key, this.onClientChanged});

  @override
  State<ClientSelector> createState() => _ClientSelectorState();
}

class _ClientSelectorState extends State<ClientSelector> {
  final ClientService _clientService = ClientService.instance;

  @override
  Widget build(BuildContext context) {
    // Só mostra o seletor em modo debug
    if (kReleaseMode) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.business, size: 20),
          const SizedBox(width: 8),
          const Text(
            'Cliente:',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          const SizedBox(width: 8),
          DropdownButton<ClientType>(
            value: _clientService.currentClientType,
            underline: const SizedBox.shrink(),
            items: ClientType.values.map((client) {
              return DropdownMenuItem<ClientType>(
                value: client,
                child: Text(client.displayName),
              );
            }).toList(),
            onChanged: (ClientType? newClient) {
              if (newClient != null) {
                setState(() {
                  _clientService.setClient(newClient);
                });
                widget.onClientChanged?.call(newClient);
              }
            },
          ),
        ],
      ),
    );
  }
}
