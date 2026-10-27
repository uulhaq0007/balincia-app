import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/store_data.dart';
import '../models/commerce.dart';
import '../state/account_store.dart';
import '../theme.dart';
import 'common.dart';

Future<void> _sheet(BuildContext context, {required String title, required Widget child}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    barrierColor: BrandColors.ink.withValues(alpha: 0.45),
    builder: (context) => ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(color: BrandColors.paper3, borderRadius: BorderRadius.circular(9)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 14, 10, 6),
                child: Row(
                  children: [
                    Expanded(child: Text(title, style: AppText.display(26))),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Flexible(child: child),
            ],
          ),
        ),
      ),
    ),
  );
}

void _copy(BuildContext context, String label, String value) {
  Clipboard.setData(ClipboardData(text: value));
  showToast(context, '$label copied');
}

/// Contact details from the store settings, each copyable.
Future<void> showConciergeSheet(BuildContext context) {
  final rows = [
    (Icons.phone_outlined, 'Call us', kConcierge.phone),
    (Icons.chat_outlined, 'WhatsApp', kConcierge.whatsapp),
    (Icons.mail_outline_rounded, 'Email', kConcierge.email),
  ];
  return _sheet(
    context,
    title: 'Scent concierge',
    child: ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
      children: [
        Text(
          'Our fragrance consultants can help you choose, layer or gift — ${kConcierge.hours}.',
          style: AppText.sans(13.5, color: BrandColors.inkSoft, height: 1.5),
        ),
        const SizedBox(height: 14),
        for (final (icon, label, value) in rows)
          Builder(
            builder: (context) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: BrandColors.paper2,
                child: Icon(icon, color: BrandColors.gold, size: 20),
              ),
              title: Text(
                label,
                style: AppText.sans(12, color: BrandColors.muted, weight: FontWeight.w700),
              ),
              subtitle: Text(value, style: AppText.sans(15, weight: FontWeight.w700)),
              trailing: TextButton.icon(
                onPressed: () => _copy(context, label == 'Email' ? 'Email address' : 'Number', value),
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Copy'),
              ),
            ),
          ),
      ],
    ),
  );
}

/// The eight boutiques from the web's STORES list.
Future<void> showBoutiquesSheet(BuildContext context) {
  return _sheet(
    context,
    title: 'Our boutiques',
    child: ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
      itemCount: kBoutiques.length,
      separatorBuilder: (_, _) => const Divider(height: 22),
      itemBuilder: (context, i) {
        final b = kBoutiques[i];
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.place_outlined, size: 20, color: BrandColors.gold),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b.city.toUpperCase(), style: AppText.eyebrow(color: BrandColors.muted, size: 9.5)),
                  const SizedBox(height: 3),
                  Text(b.name, style: AppText.sans(14.5, weight: FontWeight.w700)),
                  Text(b.address, style: AppText.sans(12.5, color: BrandColors.inkSoft, height: 1.4)),
                  const SizedBox(height: 3),
                  Text('${b.hours} · ${b.phone}', style: AppText.sans(12, color: BrandColors.muted)),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Copy phone number',
              onPressed: () => _copy(context, '${b.name} number', b.phone),
              icon: const Icon(Icons.copy_rounded, size: 18, color: BrandColors.muted),
            ),
          ],
        );
      },
    ),
  );
}

/// Edit the saved delivery address.
Future<void> showAddressSheet(BuildContext context, AccountStore account) {
  final a = account.address;
  final name = TextEditingController(text: a.fullName);
  final phone = TextEditingController(text: a.phone);
  final line1 = TextEditingController(text: a.line1);
  final city = TextEditingController(text: a.city);
  final postal = TextEditingController(text: a.postalCode);
  final form = GlobalKey<FormState>();

  Widget field(TextEditingController c, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      controller: c,
      style: AppText.sans(14.5, weight: FontWeight.w600),
      validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
      decoration: InputDecoration(labelText: label),
    ),
  );

  return _sheet(
    context,
    title: 'Delivery address',
    child: Form(
      key: form,
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(22, 6, 22, 16),
        children: [
          field(name, 'Full name'),
          field(phone, 'Mobile number'),
          field(line1, 'Address'),
          Row(
            children: [
              Expanded(flex: 3, child: field(city, 'City')),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: field(postal, 'Postcode')),
            ],
          ),
          const SizedBox(height: 6),
          Builder(
            builder: (sheetContext) => FilledButton(
              onPressed: () {
                if (!(form.currentState?.validate() ?? false)) return;
                account.updateAddress(
                  Address(
                    fullName: name.text.trim(),
                    phone: phone.text.trim(),
                    line1: line1.text.trim(),
                    city: city.text.trim(),
                    province: a.province,
                    postalCode: postal.text.trim(),
                  ),
                );
                Navigator.of(sheetContext).pop();
                showToast(context, 'Address saved');
              },
              child: const Text('SAVE ADDRESS'),
            ),
          ),
        ],
      ),
    ),
  );
}
