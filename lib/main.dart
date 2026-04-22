import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


void main() {
  runApp(const MyApp());
}


const primaryColor = Color(0xFFD4AF37); // dorado TPL
const cardColor = Color(0xFF0E1118);
const borderColor = Color(0xFF1C2230);

const String apiBase = 'https://liga-backend-f08y.onrender.com';

Widget tplCard({required Widget child}) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF111827),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.05)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.4),
          blurRadius: 10,
          offset: const Offset(0, 4),
        )
      ],
    ),
    child: child,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
Widget build(BuildContext context) {
  return MaterialApp(
    title: 'TPL Chile',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,

      // 🎨 Fondo general app
      scaffoldBackgroundColor: const Color(0xFF0B0F1A),

      // 🟨 Colores principales TPL
      primaryColor: const Color(0xFFD4AF37),

      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFD4AF37),
        secondary: Color(0xFF1E293B),
      ),

      // 🔠 Tipografía base
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Colors.white70,
        ),
      ),

      // 🔝 AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0A0D14),
        elevation: 0,
        centerTitle: false,
      ),

      // 🔻 Bottom navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.black,
        selectedItemColor: Color(0xFFD4AF37),
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
      ),
    ),
    home: const MainNavigation(),
  );
 }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int currentIndex = 0;

final pages = const [
  HomeScreen(),
  CalendarScreen(),
  StandingsScreen(),
  PlayersScreen(),
  PhotosScreen(),
];

  @override
  Widget build(BuildContext context) {

    return Scaffold(
  appBar: AppBar(
    title: Row(
      children: [
        Image.asset('assets/tpl_logo_trans.png', height: 30),
        const SizedBox(width: 10),
        const Text('TPL Chile'),
      ],
    ),
  ),

      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Calendario'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Tabla'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Jugadores'),
          BottomNavigationBarItem(icon: Icon(Icons.photo), label: 'Fotos'),
        ],
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<HomeData> futureHome;

  @override
  void initState() {
    super.initState();
    futureHome = fetchHomeData();
  }

  Future<HomeData> fetchHomeData() async {
    final response = await http.get(Uri.parse('$apiBase/home'));

    if (response.statusCode != 200) {
      throw Exception('No se pudo cargar la portada');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return HomeData.fromJson(decoded);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HomeData>(
      future: futureHome,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.amber),
          );
        }

        if (snapshot.hasError) {
          return _ErrorState(
            message: '${snapshot.error}',
            onRetry: () {
              setState(() {
                futureHome = fetchHomeData();
              });
            },
          );
        }

        final home = snapshot.data!;
        final groupedMatches = groupMatchesByTie(home.matches);
        final featuredTies = groupedMatches.take(2).toList();

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              futureHome = fetchHomeData();
            });
            await futureHome;
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Próxima jornada',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      home.nextRound?.dateLabel ?? 'Por definir',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      home.nextRound == null
                          ? 'Aún no hay jornada futura disponible.'
                          : 'Jornada ${home.nextRound!.roundNumber}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cruces destacados',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (featuredTies.isEmpty)
                      const Text(
                        'No hay encuentros disponibles.',
                        style: TextStyle(color: Colors.white70),
                      )
                    else
                      ...featuredTies.map(
                        (tie) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _TieCard(tie: tie),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tabla rápida',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (home.standings.isEmpty)
                      const Text(
                        'No hay tabla disponible.',
                        style: TextStyle(color: Colors.white70),
                      )
                    else
                      ...home.standings.take(4).map(
                        (team) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.amber.withOpacity(0.18),
                                child: Text(
                                  '${team.position}',
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  team.teamName,
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                              Text(
                                '${team.totalPoints} pts',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late Future<HomeData> futureHome;

  @override
  void initState() {
    super.initState();
    futureHome = fetchHomeData();
  }

  Future<HomeData> fetchHomeData() async {
    final response = await http.get(Uri.parse('$apiBase/home'));

    if (response.statusCode != 200) {
      throw Exception('No se pudo cargar el calendario');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return HomeData.fromJson(decoded);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HomeData>(
      future: futureHome,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.amber),
          );
        }

        if (snapshot.hasError) {
          return _ErrorState(
            message: '${snapshot.error}',
            onRetry: () {
              setState(() {
                futureHome = fetchHomeData();
              });
            },
          );
        }

        final ties = groupMatchesByTie(snapshot.data!.matches);
        final rounds = groupTiesByRound(ties);

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              futureHome = fetchHomeData();
            });
            await futureHome;
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: rounds.entries.map((entry) {
              final roundNumber = entry.key;
              final roundTies = entry.value;
              final roundDate = roundTies.isNotEmpty ? roundTies.first.dateLabel : '';

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: tplCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jornada $roundNumber',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        roundDate,
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...roundTies.map(
                        (tie) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _CalendarTieCard(tie: tie),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class StandingsScreen extends StatefulWidget {
  const StandingsScreen({super.key});

  @override
  State<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends State<StandingsScreen> {
  late Future<HomeData> futureHome;

  @override
  void initState() {
    super.initState();
    futureHome = fetchHomeData();
  }

  Future<HomeData> fetchHomeData() async {
    final response = await http.get(Uri.parse('$apiBase/home'));

    if (response.statusCode != 200) {
      throw Exception('No se pudo cargar la tabla');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return HomeData.fromJson(decoded);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HomeData>(
      future: futureHome,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.amber),
          );
        }

        if (snapshot.hasError) {
          return _ErrorState(
            message: '${snapshot.error}',
            onRetry: () {
              setState(() {
                futureHome = fetchHomeData();
              });
            },
          );
        }

        final standings = snapshot.data!.standings;

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              futureHome = fetchHomeData();
            });
            await futureHome;
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tabla oficial',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...standings.map(
                      (team) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.amber.withOpacity(0.18),
                              child: Text(
                                '${team.position}',
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    team.teamName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${team.wonGames} G • ${team.lostGames} P • Dif ${team.setsDiff}',
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${team.totalPoints} pts',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}





class _TieCard extends StatelessWidget {
  final TieItem tie;

  const _TieCard({required this.tie});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF11151F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${tie.homeTeam} vs ${tie.awayTeam}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sede ${tie.venueClub}',
                  style: const TextStyle(color: Colors.white60),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              tie.timeLabel,
              style: const TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}




class _CalendarTieCard extends StatelessWidget {
  final TieItem tie;

  const _CalendarTieCard({required this.tie});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          title: Text(
            '${tie.homeTeam} vs ${tie.awayTeam}',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.white54),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    tie.venueClub,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                Text(
                  tie.timeLabel,
                  style: const TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          children: tie.games.map((game) {
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      game.category,
                      style: const TextStyle(
                        fontSize: 12,
                        color: primaryColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    game.timeLabel,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}





class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: cardColor,
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}




class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 44, color: Colors.redAccent),
            const SizedBox(height: 12),
            const Text(
              'Error cargando datos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeData {
  final List<StandingItem> standings;
  final List<MatchGameItem> matches;
  final NextRoundData? nextRound;

  HomeData({
    required this.standings,
    required this.matches,
    required this.nextRound,
  });

  factory HomeData.fromJson(Map<String, dynamic> json) {
    final standingsJson = (json['standings'] as List<dynamic>? ?? []);
    final matchesJson = (json['matches'] as List<dynamic>? ?? []);
    final nextRoundJson = json['next_round'] as Map<String, dynamic>?;

    return HomeData(
      standings: standingsJson.map((e) => StandingItem.fromJson(e)).toList(),
      matches: matchesJson.map((e) => MatchGameItem.fromJson(e)).toList(),
      nextRound: nextRoundJson == null ? null : NextRoundData.fromJson(nextRoundJson),
    );
  }
}

class StandingItem {
  final int position;
  final String teamName;
  final int totalPoints;
  final int wonGames;
  final int lostGames;
  final int setsDiff;

  StandingItem({
    required this.position,
    required this.teamName,
    required this.totalPoints,
    required this.wonGames,
    required this.lostGames,
    required this.setsDiff,
  });

  factory StandingItem.fromJson(Map<String, dynamic> json) {
    return StandingItem(
      position: json['position'] as int? ?? 0,
      teamName: json['team_name']?.toString() ?? '',
      totalPoints: json['total_points'] as int? ?? 0,
      wonGames: json['won_games'] as int? ?? 0,
      lostGames: json['lost_games'] as int? ?? 0,
      setsDiff: json['sets_diff'] as int? ?? 0,
    );
  }
}

class MatchGameItem {
  final int matchId;
  final int roundNumber;
  final int gameNumber;
  final String homeTeam;
  final String awayTeam;
  final String venueClub;
  final String category;
  final DateTime? scheduledAt;

  MatchGameItem({
    required this.matchId,
    required this.roundNumber,
    required this.gameNumber,
    required this.homeTeam,
    required this.awayTeam,
    required this.venueClub,
    required this.category,
    required this.scheduledAt,
  });

  factory MatchGameItem.fromJson(Map<String, dynamic> json) {
    return MatchGameItem(
      matchId: json['match_id'] as int? ?? 0,
      roundNumber: json['round_number'] as int? ?? 0,
      gameNumber: json['game_number'] as int? ?? 0,
      homeTeam: json['home_team_name']?.toString() ?? '',
      awayTeam: json['away_team_name']?.toString() ?? '',
      venueClub: json['venue_club']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      scheduledAt: json['scheduled_at'] == null
          ? null
          : DateTime.tryParse(json['scheduled_at'].toString()),
    );
  }

  String get timeLabel {
    if (scheduledAt == null) return '--:--';
    final hour = scheduledAt!.hour.toString().padLeft(2, '0');
    final minute = scheduledAt!.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class TieItem {
  final int matchId;
  final int roundNumber;
  final String homeTeam;
  final String awayTeam;
  final String venueClub;
  final DateTime? scheduledAt;
  final List<MatchGameItem> games;

  TieItem({
    required this.matchId,
    required this.roundNumber,
    required this.homeTeam,
    required this.awayTeam,
    required this.venueClub,
    required this.scheduledAt,
    required this.games,
  });

  String get timeLabel {
    if (scheduledAt == null) return '--:--';
    final hour = scheduledAt!.hour.toString().padLeft(2, '0');
    final minute = scheduledAt!.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get dateLabel {
    if (scheduledAt == null) return 'Por definir';

    const weekdays = [
      '',
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ];

    const months = [
      '',
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];

    final weekday = weekdays[scheduledAt!.weekday];
    return '$weekday, ${scheduledAt!.day} de ${months[scheduledAt!.month]}';
  }
}

List<TieItem> groupMatchesByTie(List<MatchGameItem> matches) {
  final Map<int, List<MatchGameItem>> grouped = {};

  for (final match in matches) {
    grouped.putIfAbsent(match.matchId, () => []).add(match);
  }

  final ties = grouped.entries.map((entry) {
    final games = entry.value;
    games.sort((a, b) => a.gameNumber.compareTo(b.gameNumber));
    final first = games.first;

    return TieItem(
      matchId: first.matchId,
      roundNumber: first.roundNumber,
      homeTeam: first.homeTeam,
      awayTeam: first.awayTeam,
      venueClub: first.venueClub,
      scheduledAt: first.scheduledAt,
      games: games,
    );
  }).toList();

  ties.sort((a, b) {
    if (a.roundNumber != b.roundNumber) {
      return a.roundNumber.compareTo(b.roundNumber);
    }
    if (a.scheduledAt == null && b.scheduledAt == null) return 0;
    if (a.scheduledAt == null) return 1;
    if (b.scheduledAt == null) return -1;
    return a.scheduledAt!.compareTo(b.scheduledAt!);
  });

  return ties;
}

Map<int, List<TieItem>> groupTiesByRound(List<TieItem> ties) {
  final Map<int, List<TieItem>> grouped = {};

  for (final tie in ties) {
    grouped.putIfAbsent(tie.roundNumber, () => []).add(tie);
  }

  return grouped;
}

class NextRoundData {
  final int? roundNumber;
  final DateTime? date;

  NextRoundData({
    required this.roundNumber,
    required this.date,
  });

  factory NextRoundData.fromJson(Map<String, dynamic> json) {
    return NextRoundData(
      roundNumber: json['round_number'] as int?,
      date: json['date'] == null
          ? null
          : DateTime.tryParse(json['date'].toString()),
    );
  }

  String get dateLabel {
    if (date == null) return 'Por definir';

    const months = [
      '',
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre'
    ];

    return '${date!.day} de ${months[date!.month]}';
  }
}

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  late Future<List<PlayerStatsItem>> futurePlayers;

  @override
  void initState() {
    super.initState();
    futurePlayers = fetchPlayers();
  }

Future<List<PlayerStatsItem>> fetchPlayers() async {
  final response = await http.get(Uri.parse('$apiBase/players/stats'));

  if (response.statusCode != 200) {
    throw Exception('No se pudo cargar el ranking de jugadores');
  }

  final decoded = jsonDecode(response.body);

  List<PlayerStatsItem> players = [];

  if (decoded is List) {
    players = decoded.map((e) => PlayerStatsItem.fromJson(e)).toList();
  } else if (decoded is Map<String, dynamic> && decoded['players'] is List) {
    players = (decoded['players'] as List)
        .map((e) => PlayerStatsItem.fromJson(e))
        .toList();
  } else {
    throw Exception('Formato inesperado en /players/stats');
  }

  if (players.isEmpty) {
    return [
      PlayerStatsItem(
        fullName: 'Celsa Sánchez',
        teamName: 'Espacio Active',
        points: 1800,
        wins: 7,
        losses: 0,
      ),
    ];
  }

  return players;
}



  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PlayerStatsItem>>(
      future: futurePlayers,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: primaryColor),
          );
        }

        if (snapshot.hasError) {
          return _ErrorState(
            message: '${snapshot.error}',
            onRetry: () {
              setState(() {
                futurePlayers = fetchPlayers();
              });
            },
          );
        }

        final players = snapshot.data ?? [];

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              futurePlayers = fetchPlayers();
            });
            await futurePlayers;
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ranking de jugadores',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${players.length} jugadores en el ranking',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (players.isEmpty)
                const _SectionCard(
                  child: Text(
                    'Aún no hay datos de jugadores disponibles.',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              else
                ...players.asMap().entries.map((entry) {
                  final index = entry.key;
                  final player = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PlayerCard(
                      rank: index + 1,
                      player: player,
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final int rank;
  final PlayerStatsItem player;

  const _PlayerCard({
    required this.rank,
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: primaryColor.withOpacity(0.18),
            child: Text(
              '$rank',
              style: const TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  player.teamName,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    _miniBadge('${player.points} pts'),
                    _miniBadge('${player.wins} G'),
                    _miniBadge('${player.losses} P'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _miniBadge(String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        color: Colors.white70,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class PlayerStatsItem {
  final String fullName;
  final String teamName;
  final int points;
  final int wins;
  final int losses;

  PlayerStatsItem({
    required this.fullName,
    required this.teamName,
    required this.points,
    required this.wins,
    required this.losses,
  });

  factory PlayerStatsItem.fromJson(Map<String, dynamic> json) {
    final firstName = json['first_name']?.toString() ?? '';
    final lastName = json['last_name']?.toString() ?? '';
    final fallbackName = json['player_name']?.toString() ?? '';

    final fullName = ('$firstName $lastName').trim().isNotEmpty
        ? ('$firstName $lastName').trim()
        : fallbackName;

    return PlayerStatsItem(
      fullName: fullName.isEmpty ? 'Jugador sin nombre' : fullName,
      teamName: json['team_name']?.toString() ??
          json['club_name']?.toString() ??
          'Sin equipo',
      points: (json['points'] as num?)?.toInt() ??
          (json['total_points'] as num?)?.toInt() ??
          0,
      wins: (json['wins'] as num?)?.toInt() ??
          (json['won_games'] as num?)?.toInt() ??
          0,
      losses: (json['losses'] as num?)?.toInt() ??
          (json['lost_games'] as num?)?.toInt() ??
          0,
    );
  }
}

class PhotosScreen extends StatelessWidget {
  const PhotosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final albums = [
      PhotoAlbum(
        title: 'Selectivos Espacio Active',
        subtitle: 'Jornada de selectivos en Espacio Active',
        photos: const [
          'assets/photos/1.jpg',
          'assets/photos/2.jpg',
          'assets/photos/3.jpg',
          'assets/photos/4.jpg',
          'assets/photos/5.jpg',
          'assets/photos/6.jpg',
        ],
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Galería',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Fotos destacadas de jornadas, selectivos y momentos de la liga.',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...albums.map(
          (album) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _PhotoAlbumCard(album: album),
          ),
        ),
      ],
    );
  }
}

class _PhotoAlbumCard extends StatelessWidget {
  final PhotoAlbum album;

  const _PhotoAlbumCard({required this.album});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            album.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            album.subtitle,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: album.photos.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final photoPath = album.photos[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PhotoViewerScreen(
                        imagePath: photoPath,
                        title: album.title,
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        photoPath,
                        fit: BoxFit.cover,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.center,
                            colors: [
                              Colors.black.withOpacity(0.35),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class PhotoViewerScreen extends StatelessWidget {
  final String imagePath;
  final String title;

  const PhotoViewerScreen({
    super.key,
    required this.imagePath,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.asset(imagePath),
        ),
      ),
    );
  }
}

class PhotoAlbum {
  final String title;
  final String subtitle;
  final List<String> photos;

  const PhotoAlbum({
    required this.title,
    required this.subtitle,
    required this.photos,
  });
}
