import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sov_inte_forbi/config.dart';
import 'package:sov_inte_forbi/models/station.dart';

class TrafikverketService {
  List<Station>? _cachedStations;

  Future<List<Station>> fetchStations({bool forceRefresh = false}) async {
    if (_cachedStations != null && !forceRefresh) {
      return _cachedStations!;
    }

    final body = '''
<REQUEST>
  <LOGIN authenticationkey="$trafikverketApiKey" />
  <QUERY objecttype="TrainStation" schemaversion="1.4">
    <FILTER>
      <EQ name="Advertised" value="true" />
    </FILTER>
    <INCLUDE>LocationSignature</INCLUDE>
    <INCLUDE>AdvertisedLocationName</INCLUDE>
    <INCLUDE>Geometry.WGS84</INCLUDE>
    <INCLUDE>CountyNo</INCLUDE>
  </QUERY>
</REQUEST>''';

    final response = await http.post(
      Uri.parse(trafikverketEndpoint),
      headers: {'Content-Type': 'text/xml'},
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Trafikverket API error: ${response.statusCode} ${response.body}',
      );
    }

    final json = jsonDecode(response.body);
    final results = json['RESPONSE']?['RESULT'] as List?;
    if (results == null || results.isEmpty) {
      throw Exception('No results from Trafikverket');
    }

    final stationData = results[0]['TrainStation'] as List? ?? [];
    _cachedStations =
        stationData
            .map((s) => Station.fromTrafikverketJson(s as Map<String, dynamic>))
            .where((s) => s.latitude != 0 && s.longitude != 0)
            .toList();

    return _cachedStations!;
  }

  void clearCache() {
    _cachedStations = null;
  }
}
