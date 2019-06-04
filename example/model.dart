import 'dart:convert';

@pragma("model")
class Person {
  @pragma("json:'name'")
  String name;

  @pragma("json:'age'")
  int age;

  @pragma("json:'primary_address'")
  Address primaryAddress = Address();

  @pragma("json:'addresses'")
  List<Address> addresses = [];

  //GENERATED
  //GENERATED
}

@pragma("model")
class Address {
  @pragma("json:'street'")
  String street = "";

  @pragma("json:'pin_code'")
  String pinCode = "";

  //GENERATED
  //GENERATED
}
