import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final _db = FirebaseFirestore.instance;
final _auth = FirebaseAuth.instance;

// ---------------------------------------------------------------- Colors
const _kPrimary = Color(0xFF4F46E5); // indigo
const _kViolet = Color(0xFF7C3AED);
const _kTeal = Color(0xFF14B8A6);
const _kBg = Color(0xFFF4F5FB);
const _kText = Color(0xFF1E1B4B);

const _kGradient = LinearGradient(
  colors: [_kPrimary, _kViolet],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const _kOptionColors = [
  Color(0xFF4F46E5),
  Color(0xFF14B8A6),
  Color(0xFFF59E0B),
  Color(0xFFEC4899),
  Color(0xFF0EA5E9),
  Color(0xFF22C55E),
];

ThemeData _buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: _kPrimary,
    secondary: _kTeal,
    brightness: Brightness.light,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: _kBg,
    appBarTheme: const AppBarTheme(
      backgroundColor: _kPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: _kViolet),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: _kPrimary),
  );
}

InputDecoration _dec(String label, {IconData? icon}) => InputDecoration(
      labelText: label,
      prefixIcon: icon == null ? null : Icon(icon, color: _kPrimary),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD9DBF0))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD9DBF0))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kPrimary, width: 2)),
    );

Widget _card({required Widget child, EdgeInsets? padding}) => Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5E7F5)),
      ),
      child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
    );

// ---------------------------------------------------------------- Main
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const VoteApp());
}

void _log(String action, {String? pollId}) {
  final u = _auth.currentUser;
  if (u == null) return;
  _db.collection('activity').add({
    'uid': u.uid, 'email': u.email, 'action': action,
    'pollId': pollId, 'at': FieldValue.serverTimestamp(),
  });
}

void _toast(BuildContext c, String m) => ScaffoldMessenger.of(c).showSnackBar(
      SnackBar(
        content: Text(m),
        backgroundColor: _kText,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

class VoteApp extends StatelessWidget {
  const VoteApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Online Voting',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: StreamBuilder<User?>(
          stream: _auth.authStateChanges(),
          builder: (_, s) {
            if (s.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            return s.data == null ? const LoginPage() : const HomePage();
          },
        ),
      );
}

// ---------------------------------------------------------------- Auth
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController(), _pass = TextEditingController();
  bool _register = false, _busy = false;

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      final e = _email.text.trim(), p = _pass.text;
      if (_register) {
        final c = await _auth.createUserWithEmailAndPassword(email: e, password: p);
        await _db.doc('users/${c.user!.uid}').set(
            {'email': e, 'role': 'user', 'createdAt': FieldValue.serverTimestamp()});
        _log('register');
      } else {
        await _auth.signInWithEmailAndPassword(email: e, password: p);
        _log('login');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) _toast(context, e.message ?? 'Authentication failed');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: _kGradient),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.how_to_vote, size: 48, color: _kPrimary),
                  ),
                  const SizedBox(height: 16),
                  const Text('Online Voting',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Secure. Simple. One vote each.',
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(_register ? 'Create account' : 'Welcome back',
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: _kText)),
                        const SizedBox(height: 16),
                        TextField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _dec('Email', icon: Icons.email_outlined)),
                        const SizedBox(height: 12),
                        TextField(
                            controller: _pass,
                            obscureText: true,
                            decoration:
                                _dec('Password (min 6)', icon: Icons.lock_outline)),
                        const SizedBox(height: 16),
                        FilledButton(
                            onPressed: _busy ? null : _submit,
                            child: _busy
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : Text(_register ? 'Create account' : 'Sign in')),
                        TextButton(
                            onPressed: () => setState(() => _register = !_register),
                            child: Text(_register
                                ? 'Have an account? Sign in'
                                : 'New here? Register')),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      );
}

// ---------------------------------------------------------------- Model
enum PollStatus { upcoming, open, ended, closed }

class Poll {
  final String id, title, description, visibility; // live | after_end | admin_only
  final List<String> options;
  final Map<int, int> counts;
  final DateTime start, end;
  final bool closed;
  Poll(DocumentSnapshot<Map<String, dynamic>> d)
      : id = d.id,
        title = d['title'],
        description = d['description'] ?? '',
        visibility = d['visibility'],
        options = List<String>.from(d['options']),
        counts = {
          for (final e in (d['counts'] as Map? ?? {}).entries)
            int.parse('${e.key}'): (e.value as num).toInt()
        },
        start = (d['startAt'] as Timestamp).toDate(),
        end = (d['endAt'] as Timestamp).toDate(),
        closed = d['closed'] ?? false;

  PollStatus get status {
    final n = DateTime.now();
    if (closed) return PollStatus.closed;
    if (n.isBefore(start)) return PollStatus.upcoming;
    if (n.isAfter(end)) return PollStatus.ended;
    return PollStatus.open;
  }

  bool get isOver => status == PollStatus.ended || status == PollStatus.closed;
  bool resultsVisible(bool admin) =>
      admin || visibility == 'live' || (visibility == 'after_end' && isOver);
  int get total => counts.values.fold(0, (a, b) => a + b);
}

class StatusBadge extends StatelessWidget {
  final PollStatus s;
  const StatusBadge(this.s, {super.key});

  Color get _color => switch (s) {
        PollStatus.open => const Color(0xFF16A34A),
        PollStatus.upcoming => const Color(0xFFF59E0B),
        PollStatus.ended => const Color(0xFF6B7280),
        PollStatus.closed => const Color(0xFFDC2626),
      };

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: _color.withAlpha(30),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(s.name.toUpperCase(),
            style: TextStyle(
                color: _color, fontSize: 11, fontWeight: FontWeight.bold)),
      );
}

// ---------------------------------------------------------------- Home
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser!.uid;
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _db.doc('users/$uid').snapshots(),
      builder: (context, us) {
        final admin = us.data?.data()?['role'] == 'admin';
        return Scaffold(
          appBar: AppBar(
            flexibleSpace:
                Container(decoration: const BoxDecoration(gradient: _kGradient)),
            title: const Text('Polls & Elections'),
            actions: [
              if (admin)
                IconButton(
                    tooltip: 'Admin panel',
                    icon: const Icon(Icons.admin_panel_settings),
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AdminPage()))),
              IconButton(
                  tooltip: 'Sign out',
                  icon: const Icon(Icons.logout),
                  onPressed: () {
                    _log('logout');
                    _auth.signOut();
                  }),
            ],
          ),
          body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _db.collection('polls').orderBy('createdAt', descending: true).snapshots(),
            builder: (_, s) {
              if (!s.hasData) return const Center(child: CircularProgressIndicator());
              final polls = s.data!.docs.map(Poll.new).toList();
              if (polls.isEmpty) {
                return const Center(
                    child: Text('No polls yet.',
                        style: TextStyle(color: _kText, fontSize: 16)));
              }
              return ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  for (final p in polls)
                    _card(
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        leading: const CircleAvatar(
                            backgroundColor: Color(0xFFE0E7FF),
                            child: Icon(Icons.poll, color: _kPrimary)),
                        title: Text(p.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, color: _kText)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(children: [
                            StatusBadge(p.status),
                            const SizedBox(width: 8),
                            Flexible(
                                child: Text(
                                    'ends ${DateFormat.yMMMd().add_jm().format(p.end)}',
                                    style: const TextStyle(fontSize: 12))),
                          ]),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: _kPrimary),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => PollPage(pollId: p.id, admin: admin))),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------- Poll + vote
class PollPage extends StatefulWidget {
  final String pollId;
  final bool admin;
  const PollPage({super.key, required this.pollId, required this.admin});
  @override
  State<PollPage> createState() => _PollPageState();
}

class _PollPageState extends State<PollPage> {
  int? _sel;
  bool _busy = false;

  Future<void> _vote(Poll p) async {
    final u = _auth.currentUser!;
    setState(() => _busy = true);
    try {
      await _db.runTransaction((t) async {
        final vRef = _db.doc('votes/${p.id}_${u.uid}');
        if ((await t.get(vRef)).exists) throw 'You have already voted in this poll.';
        t.set(vRef, {
          'pollId': p.id, 'uid': u.uid, 'option': _sel,
          'at': FieldValue.serverTimestamp(),
        });
        t.update(_db.doc('polls/${p.id}'), {'counts.$_sel': FieldValue.increment(1)});
        t.set(_db.collection('activity').doc(), {
          'uid': u.uid, 'email': u.email, 'action': 'vote',
          'pollId': p.id, 'at': FieldValue.serverTimestamp(),
        });
      });
      if (mounted) _toast(context, 'Vote recorded. Thank you!');
    } catch (e) {
      if (mounted) _toast(context, '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(
        flexibleSpace:
            Container(decoration: const BoxDecoration(gradient: _kGradient)),
        title: const Text('Poll'),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _db.doc('polls/${widget.pollId}').snapshots(),
        builder: (_, ps) {
          if (!ps.hasData || !ps.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }
          final p = Poll(ps.data!);
          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _db.doc('votes/${p.id}_$uid').snapshots(),
            builder: (_, vs) {
              final voted = vs.data?.exists ?? false;
              final mine = voted ? vs.data!['option'] as int : null;
              final canVote = p.status == PollStatus.open && !voted;
              return ListView(padding: const EdgeInsets.all(16), children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: _kGradient,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    if (p.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(p.description,
                          style: const TextStyle(color: Colors.white70)),
                    ],
                    const SizedBox(height: 12),
                    Row(children: [
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20)),
                          child: StatusBadge(p.status)),
                    ]),
                    const SizedBox(height: 8),
                    Text(
                        '${DateFormat.yMMMd().add_jm().format(p.start)} → ${DateFormat.yMMMd().add_jm().format(p.end)}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ]),
                ),
                const SizedBox(height: 16),
                if (canVote) ...[
                  for (var i = 0; i < p.options.length; i++)
                    _card(
                      child: RadioListTile<int>(
                          value: i,
                          groupValue: _sel,
                          activeColor: _kPrimary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          title: Text(p.options[i],
                              style: const TextStyle(color: _kText)),
                          onChanged: (v) => setState(() => _sel = v)),
                    ),
                  const SizedBox(height: 4),
                  FilledButton(
                      onPressed: _sel == null || _busy ? null : () => _vote(p),
                      child: const Text('Submit vote')),
                ] else
                  Chip(
                      backgroundColor:
                          voted ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                      side: BorderSide.none,
                      avatar: Icon(voted ? Icons.check_circle : Icons.info_outline,
                          color: voted
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFD97706)),
                      label: Text(voted
                          ? 'You voted for: ${p.options[mine!]}'
                          : p.status == PollStatus.upcoming
                              ? 'Voting has not started yet'
                              : 'Voting is closed')),
                const SizedBox(height: 16),
                if (p.resultsVisible(widget.admin))
                  _card(padding: const EdgeInsets.all(16), child: ResultsView(p))
                else
                  Text(
                      p.visibility == 'after_end'
                          ? 'Results will be shown after voting ends.'
                          : 'Results are hidden by the administrator.',
                      style: const TextStyle(fontStyle: FontStyle.italic)),
              ]);
            },
          );
        },
      ),
    );
  }
}

class ResultsView extends StatelessWidget {
  final Poll p;
  const ResultsView(this.p, {super.key});
  @override
  Widget build(BuildContext context) {
    final total = p.total;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Live results · $total votes',
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: _kText)),
      const SizedBox(height: 10),
      for (var i = 0; i < p.options.length; i++) ...[
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Flexible(child: Text(p.options[i])),
          Text(
              '${p.counts[i] ?? 0} (${total == 0 ? 0 : ((p.counts[i] ?? 0) * 100 / total).round()}%)',
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 4),
        LinearProgressIndicator(
            value: total == 0 ? 0 : (p.counts[i] ?? 0) / total,
            minHeight: 10,
            color: _kOptionColors[i % _kOptionColors.length],
            backgroundColor: const Color(0xFFE8EAF6),
            borderRadius: BorderRadius.circular(6)),
        const SizedBox(height: 12),
      ],
    ]);
  }
}

// ---------------------------------------------------------------- Admin
class AdminPage extends StatelessWidget {
  const AdminPage({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            flexibleSpace:
                Container(decoration: const BoxDecoration(gradient: _kGradient)),
            title: const Text('Admin panel'),
            bottom: const TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: _kTeal,
              indicatorWeight: 3,
              tabs: [
                Tab(icon: Icon(Icons.poll), text: 'Polls'),
                Tab(icon: Icon(Icons.add_circle_outline), text: 'Create'),
                Tab(icon: Icon(Icons.history), text: 'Activity'),
              ],
            ),
          ),
          body: const TabBarView(children: [_AdminPolls(), _CreatePoll(), _ActivityLog()]),
        ),
      );
}

class _AdminPolls extends StatelessWidget {
  const _AdminPolls();
  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _db.collection('polls').orderBy('createdAt', descending: true).snapshots(),
        builder: (_, s) {
          if (!s.hasData) return const Center(child: CircularProgressIndicator());
          return ListView(padding: const EdgeInsets.all(12), children: [
            for (final d in s.data!.docs.map(Poll.new))
              _card(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                        child: Text(d.title,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _kText))),
                    StatusBadge(d.status),
                    if (!d.closed)
                      IconButton(
                          tooltip: 'Close now',
                          icon: const Icon(Icons.lock_outline, color: Color(0xFFF59E0B)),
                          onPressed: () => _db.doc('polls/${d.id}').update({'closed': true})),
                    IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
                        onPressed: () => _db.doc('polls/${d.id}').delete()),
                  ]),
                  Text('Visibility: ${d.visibility}',
                      style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 10),
                  ResultsView(d),
                ]),
              ),
          ]);
        },
      );
}

class _CreatePoll extends StatefulWidget {
  const _CreatePoll();
  @override
  State<_CreatePoll> createState() => _CreatePollState();
}

class _CreatePollState extends State<_CreatePoll> {
  final _title = TextEditingController(),
      _desc = TextEditingController(),
      _opts = TextEditingController(),
      _hours = TextEditingController(text: '24');
  String _vis = 'live';
  DateTime _start = DateTime.now();

  Future<void> _pickStart() async {
    final d = await showDatePicker(
        context: context, initialDate: _start,
        firstDate: DateTime.now().subtract(const Duration(days: 1)),
        lastDate: DateTime.now().add(const Duration(days: 365)));
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_start));
    if (t == null) return;
    setState(() => _start = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  Future<void> _create() async {
    final opts = _opts.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final hrs = double.tryParse(_hours.text);
    if (_title.text.trim().isEmpty || opts.length < 2 || hrs == null || hrs <= 0) {
      return _toast(context, 'Need a title, 2+ options (one per line) and a valid duration.');
    }
    await _db.collection('polls').add({
      'title': _title.text.trim(), 'description': _desc.text.trim(),
      'options': opts, 'counts': {for (var i = 0; i < opts.length; i++) '$i': 0},
      'startAt': Timestamp.fromDate(_start),
      'endAt': Timestamp.fromDate(_start.add(Duration(minutes: (hrs * 60).round()))),
      'visibility': _vis, 'closed': false,
      'createdBy': _auth.currentUser!.uid, 'createdAt': FieldValue.serverTimestamp(),
    });
    _title.clear(); _desc.clear(); _opts.clear();
    if (mounted) _toast(context, 'Poll created');
  }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
        TextField(controller: _title, decoration: _dec('Title', icon: Icons.title)),
        const SizedBox(height: 12),
        TextField(controller: _desc, decoration: _dec('Description', icon: Icons.notes)),
        const SizedBox(height: 12),
        TextField(
            controller: _opts, minLines: 3, maxLines: 8,
            decoration: _dec('Options (one per line)', icon: Icons.list)),
        const SizedBox(height: 12),
        _card(
          child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Starts: ${DateFormat.yMMMd().add_jm().format(_start)}'),
              trailing: const Icon(Icons.schedule, color: _kPrimary),
              onTap: _pickStart),
        ),
        TextField(
            controller: _hours, keyboardType: TextInputType.number,
            decoration: _dec('Duration (hours)', icon: Icons.timer_outlined)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _vis,
          decoration: _dec('Result visibility', icon: Icons.visibility_outlined),
          items: const [
            DropdownMenuItem(value: 'live', child: Text('Live (everyone)')),
            DropdownMenuItem(value: 'after_end', child: Text('After voting ends')),
            DropdownMenuItem(value: 'admin_only', child: Text('Admins only')),
          ],
          onChanged: (v) => setState(() => _vis = v!),
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: _create, child: const Text('Create poll')),
      ]);
}

class _ActivityLog extends StatelessWidget {
  const _ActivityLog();

  Color _color(String a) => switch (a) {
        'vote' => const Color(0xFF16A34A),
        'login' => _kPrimary,
        'logout' => const Color(0xFF6B7280),
        _ => _kTeal,
      };

  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _db.collection('activity').orderBy('at', descending: true).limit(100).snapshots(),
        builder: (_, s) {
          if (!s.hasData) return const Center(child: CircularProgressIndicator());
          return ListView(padding: const EdgeInsets.all(12), children: [
            for (final d in s.data!.docs)
              _card(
                child: ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: _color(d['action']).withAlpha(30),
                    child: Icon(
                      switch (d['action']) {
                        'vote' => Icons.how_to_vote,
                        'login' => Icons.login,
                        'logout' => Icons.logout,
                        _ => Icons.person_add,
                      },
                      size: 18,
                      color: _color(d['action']),
                    ),
                  ),
                  title: Text('${d['email']} · ${d['action']}'),
                  subtitle: Text((d['at'] as Timestamp?) == null
                      ? '…'
                      : DateFormat.yMMMd().add_jms().format((d['at'] as Timestamp).toDate())),
                ),
              ),
          ]);
        },
      );
}