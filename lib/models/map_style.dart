import 'package:flutter/material.dart';

class MapStyle {
  const MapStyle({
    required this.id,
    required this.name,
    required this.price,
    required this.background,
    required this.floor,
    required this.edge,
  });

  final String id;
  final String name;
  final int price;

  final Color background;
  final Color floor;
  final Color edge;
}

const List<MapStyle> mapStyles = [
  MapStyle(
    id: 'neon_city',
    name: 'Neon City',
    price: 0,
    background: Color(0xFF080D20),
    floor: Color(0xFF101832),
    edge: Color(0xFF29CBE7),
  ),
  MapStyle(
    id: 'cyber_tunnel',
    name: 'Cyber Tunnel',
    price: 2500,
    background: Color(0xFF10081E),
    floor: Color(0xFF1A1030),
    edge: Color(0xFF9A69FF),
  ),
  MapStyle(
    id: 'space_station',
    name: 'Space Station',
    price: 4500,
    background: Color(0xFF040A17),
    floor: Color(0xFF111C2A),
    edge: Color(0xFF5AC8FA),
  ),
  MapStyle(
    id: 'lava_core',
    name: 'Lava Core',
    price: 7000,
    background: Color(0xFF190806),
    floor: Color(0xFF26100D),
    edge: Color(0xFFFF633D),
  ),
  MapStyle(
    id: 'frozen_world',
    name: 'Frozen World',
    price: 10000,
    background: Color(0xFF071626),
    floor: Color(0xFF10273A),
    edge: Color(0xFF9DEBFF),
  ),
  MapStyle(
    id: 'dark_galaxy',
    name: 'Dark Galaxy',
    price: 14000,
    background: Color(0xFF090513),
    floor: Color(0xFF151027),
    edge: Color(0xFFC56BFF),
  ),
];