// Saved looks, my orders (with studio message thread) and the profile / settings screen.
import 'package:material_ui/material_ui.dart';

import '../models.dart';
import '../state.dart';
import '../ui.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final saved = outfits.where((o) => s.favorites.contains(o.id)).toList();
    return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
      pageHeader('Saved Looks', 'Styles you love, ready to commission.',
          image: 'assets/images/outfit_ankara_elegance.jpg', icon: Icons.favorite_border, eyebrow: 'Your lookbook', tint: const Color(0xFFFFE4EF),
          trailing: bannerChip(Icons.favorite, '${saved.length} saved')),
      if (saved.isEmpty)
        _empty(Icons.favorite_border, 'No saved looks yet', 'Explore the lookbook and tap the heart on any design you love.', 'Browse Lookbook', () => s.go(AppTab.home))
      else
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: LookbookGrid(items: saved)),
    ]);
  }
}

Widget _empty(IconData icon, String title, String text, String? action, VoidCallback? on) => Padding(
      padding: const EdgeInsets.all(16),
      child: card(padding: const EdgeInsets.all(28), child: Column(children: [
        Container(width: 64, height: 64, decoration: const BoxDecoration(color: lavender, shape: BoxShape.circle), child: Icon(icon, color: purple, size: 30)),
        const SizedBox(height: 14),
        Text(title, style: display(18), textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(text, textAlign: TextAlign.center, style: const TextStyle(color: muted, height: 1.4)),
        if (action != null) ...[const SizedBox(height: 16), FilledButton(onPressed: on, child: Text(action))],
      ])),
    );

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final drafts = <String, TextEditingController>{};

  @override
  void dispose() {
    for (final c in drafts.values) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
      pageHeader('My Orders', 'Track each garment, fitting updates and cut-sheets.',
          image: 'assets/images/outfit_classic_suit.jpg', icon: Icons.shopping_bag_outlined, eyebrow: 'Your commissions', tint: const Color(0xFFE0ECFF),
          trailing: bannerChip(Icons.receipt_long, '${s.orders.length} ${s.orders.length == 1 ? 'order' : 'orders'}')),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46), backgroundColor: Colors.white),
          onPressed: () => s.go(AppTab.tailorDesk), icon: const Icon(Icons.work_outline), label: const Text('Tailor Studio Desk'))),
      const SizedBox(height: 8),
      if (s.orders.isEmpty)
        _empty(Icons.shopping_bag_outlined, 'Your tailoring orders', 'Your custom commissions will appear here once you submit a fitting request.', 'Book a Fitting', () => s.go(AppTab.book))
      else
        for (final o in s.orders) Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 8), child: _order(s, o)),
      Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), child: Text('Order journey', style: display(20))),
      for (final st in orderStages) Padding(padding: const EdgeInsets.fromLTRB(16, 10, 16, 0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.check_circle_outline, color: purple, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(st, style: const TextStyle(fontWeight: FontWeight.w800)),
          Text(orderStageInfo[st]!, style: const TextStyle(color: muted, fontSize: 12.5)),
        ])),
      ])),
    ]);
  }

  Widget _order(AppState s, TailoringOrder o) {
    final idx = orderStages.indexOf(o.stage);
    final draft = drafts.putIfAbsent(o.id, TextEditingController.new);
    void send() { if (draft.text.trim().isEmpty) return; s.postMessage(o, 'Client', draft.text.trim()); draft.clear(); }
    return card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(borderRadius: BorderRadius.circular(14), child: SizedBox(width: 76, height: 96, child: orderImage(o.image))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${o.id} · ${o.createdAt}${o.isRushOrder ? ' · Rush request' : ''}', style: const TextStyle(color: muted, fontSize: 11.5)),
          Text(o.outfitName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          Text('${o.atelierName} · ${o.fitProfileLabel} · ${o.priceLabel}', style: const TextStyle(color: muted, fontSize: 12)),
          Text('Fabric: ${o.fabricChoice}${o.eventDate != null ? ' · Event: ${o.eventDate}' : ''}', style: const TextStyle(color: muted, fontSize: 12)),
          const SizedBox(height: 6),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: lavender, borderRadius: BorderRadius.circular(8)),
              child: Text('${o.stage} · ${o.paymentStatus}', style: const TextStyle(color: purple, fontSize: 11.5, fontWeight: FontWeight.w700))),
        ])),
      ]),
      const SizedBox(height: 10),
      Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: () => showCutSheet(context, o), icon: const Icon(Icons.description_outlined, size: 18), label: const Text('Cut-Sheet'))),
      Row(children: [
        for (var i = 0; i < orderStages.length; i++) Expanded(child: Padding(padding: EdgeInsets.only(right: i < 3 ? 6 : 0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(height: 6, decoration: BoxDecoration(color: i <= idx ? purple : lavender, borderRadius: BorderRadius.circular(3))),
          const SizedBox(height: 4),
          Text(orderStages[i], style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: i <= idx ? dark : muted)),
        ]))),
      ]),
      const SizedBox(height: 14),
      const Row(children: [Icon(Icons.forum_outlined, size: 18, color: purple), SizedBox(width: 6), Text('Studio Updates & Fitting Notes', style: TextStyle(fontWeight: FontWeight.w800))]),
      const SizedBox(height: 8),
      if (o.messages.isEmpty)
        const Text('No fitting photos or notes posted yet. Leave a question for the studio below.', style: TextStyle(color: muted, fontSize: 12.5))
      else
        for (final m in o.messages) _bubble(o, m),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: TextField(controller: draft, onSubmitted: (_) => send(), textInputAction: TextInputAction.send,
            decoration: const InputDecoration(isDense: true, hintText: 'Message the studio about your fitting...'))),
        const SizedBox(width: 8),
        IconButton.filled(onPressed: send, icon: const Icon(Icons.send)),
      ]),
    ]));
  }
}

Widget _bubble(TailoringOrder o, OrderMessage m) {
  final tailor = m.sender == 'Tailor';
  return Container(
    margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: tailor ? lavender.withValues(alpha: 0.55) : bg, borderRadius: BorderRadius.circular(16), border: tailor ? null : Border.all(color: line)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(tailor ? o.atelierName : 'You', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12))),
        Text(m.timestamp, style: const TextStyle(color: muted, fontSize: 11)),
      ]),
      const SizedBox(height: 4),
      Text(m.text, style: const TextStyle(fontSize: 13)),
      if (m.image != null) Padding(padding: const EdgeInsets.only(top: 8), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(m.image!, height: 180, fit: BoxFit.cover))),
    ]),
  );
}

Widget messageBubble(TailoringOrder o, OrderMessage m) => _bubble(o, m);

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final u = s.user!;
    String n(int c, String one, String many) => '$c ${c == 1 ? one : many}';
    final rows = <(IconData, String, String, VoidCallback)>[
      (Icons.favorite_border, 'Saved Looks', n(s.favorites.length, 'saved design', 'saved designs'), () => s.go(AppTab.saved)),
      (Icons.straighten, 'My Fit Profiles', '${n(s.profiles.length, 'measurement profile', 'measurement profiles')} saved', () => s.go(AppTab.studio)),
      (Icons.shopping_bag_outlined, 'My Orders', n(s.orders.length, 'custom order', 'custom orders'), () => s.go(AppTab.orders)),
      (Icons.storefront_outlined, 'Book a Fitting', 'Studio details & submit a custom order', () => s.go(AppTab.book)),
      (Icons.work_outline, 'Tailor Studio Desk', 'Manage incoming orders, WIP photos, payments & cut-sheets', () => s.go(AppTab.tailorDesk)),
      (Icons.settings_outlined, 'Settings & Privacy', 'Notifications and measurement privacy', () => _sheet(context, 'settings')),
      (Icons.help_outline, 'Help & Support', 'Measuring tips and order assistance', () => _sheet(context, 'help')),
    ];
    return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
      pageHeader(u.name, u.email,
          image: 'assets/images/outfit_weekend_fit.jpg', icon: Icons.person_outline, eyebrow: u.isGuest ? 'Guest account' : 'My account', tint: const Color(0xFFFFE9D9),
          trailing: bannerChip(Icons.checkroom, '${s.favorites.length} saved · ${s.orders.length} orders')),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: card(padding: EdgeInsets.zero, child: Column(children: [
        for (final (i, r) in rows.indexed) ...[
          ListTile(
            leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: lavender, borderRadius: BorderRadius.circular(12)), child: Icon(r.$1, color: purple)),
            title: Text(r.$2, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(r.$3, style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right), onTap: r.$4,
          ),
          if (i < rows.length - 1) const Divider(height: 1, indent: 70),
        ],
      ]))),
      const SizedBox(height: 14),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50), foregroundColor: rose, backgroundColor: Colors.white),
          onPressed: s.signOut, icon: const Icon(Icons.logout), label: const Text('Sign Out'))),
    ]);
  }

  void _sheet(BuildContext context, String which) {
    showModalBottomSheet(context: context, isScrollControlled: true, useSafeArea: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (c) => _InfoSheet(start: which));
  }
}

class _InfoSheet extends StatefulWidget {
  final String start;
  const _InfoSheet({required this.start});
  @override
  State<_InfoSheet> createState() => _InfoSheetState();
}

class _InfoSheetState extends State<_InfoSheet> {
  late String view = widget.start;
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final title = {'settings': 'Settings & Privacy', 'terms': 'Terms & Conditions', 'privacy': 'Privacy Policy', 'help': 'Help & Support'}[view]!;
    Widget back() => TextButton(onPressed: () => setState(() => view = 'settings'), child: const Text('Back to Settings'));
    return Padding(padding: const EdgeInsets.fromLTRB(22, 18, 22, 28), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text(title, style: display(20))), IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))]),
      const SizedBox(height: 8),
      if (view == 'settings') ...[
        SwitchListTile(contentPadding: EdgeInsets.zero, value: s.notifications, onChanged: (v) => s.setSettings(notif: v),
            title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w700)), subtitle: const Text('Style curation and tailoring order updates')),
        SwitchListTile(contentPadding: EdgeInsets.zero, value: s.measurementPrivacy, onChanged: (v) => s.setSettings(privacy: v),
            title: const Text('Measurement privacy', style: TextStyle(fontWeight: FontWeight.w700)), subtitle: const Text('Share measurements only when submitting a custom order')),
        ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.description_outlined), title: const Text('Terms & Conditions'), onTap: () => setState(() => view = 'terms')),
        ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.shield_outlined), title: const Text('Privacy Policy'), onTap: () => setState(() => view = 'privacy')),
      ],
      if (view == 'terms') ...[
        const Text('TrueFit AI provides style inspiration, AI-assisted measurement estimates, and custom fitting workflows for the studio.'),
        const SizedBox(height: 8),
        const Text('Always review AI-generated measurements against a physical tape measure before final cutting on bespoke commissions.'),
        back(),
      ],
      if (view == 'privacy') ...[
        const Text('Your measurement profiles, saved looks, and order records are stored on this device and attached only when you submit a fitting request.'),
        const SizedBox(height: 8),
        const Text('Photos used in Fit Studio or Book Fitting are sent to the TrueFit server for analysis on demand and are not stored there.'),
        back(),
      ],
      if (view == 'help') ...[
        const Text('Tips for accurate AI Fit Studio scans', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        for (final t in const ['Stand straight in natural daylight wearing fitted clothing.', 'Add an optional side-profile photo for sharper bust/waist/hip depth.',
            'Save separate profiles for group or Aso-ebi orders in Fit Studio.'])
          Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('• $t')),
      ],
    ]));
  }
}
