class FormData {
  int? id;
  String tagged_location;
  String user_houseNumber;

  FormData({
    this.id,
    required this.tagged_location,
    required this.user_houseNumber,
  });

  FormData.fromMap(Map<String, dynamic> item)
      : id = item["id"],
        tagged_location = item["tagged_location"],
        user_houseNumber = item["user_houseNumber"];

  Map<String, Object> toMap() {
    return {
      'tagged_location': tagged_location,
      'user_houseNumber': user_houseNumber,


    };
  }
}
