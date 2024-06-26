import 'dart:convert';
import 'package:http/http.dart' as http;
import 'model.dart';

class DetectService {
  final String _url = 'https://onnxai.azurewebsites.net/api/Detection/detect';

  Future<ModelOutput?> detectDefects(String imagePath) async {
    var request = http.MultipartRequest('POST', Uri.parse(_url));
    request.files
        .add(await http.MultipartFile.fromPath('UploadedFile', imagePath));

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.toBytes();
        var responseString = String.fromCharCodes(responseData);
        print('Response: $responseString'); // Log the response string

        var jsonResponse = jsonDecode(responseString);
        print('JSON: $jsonResponse'); // Log the JSON response
        if (jsonResponse is List) {
          print('List detected');
          print("object type: ${ModelOutput.fromJson(jsonResponse)}");
          return ModelOutput.fromJson(jsonResponse);
        } else {
          print(
              'Unexpected response format: $jsonResponse'); // Log unexpected format
          throw Exception('Unexpected response format');
        }
      } else {
        print(
            'Failed response code: ${response.statusCode}'); // Log failure response code
        throw Exception('Failed to get a successful response from the server');
      }
    } catch (e) {
      print('Error: $e'); // Log the error
      return null;
    }
  }
}
