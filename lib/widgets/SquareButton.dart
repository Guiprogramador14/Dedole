import 'package:flutter/material.dart';

Widget buildSquareButton({
  required Widget icon,
  required String label,
  required VoidCallback onTap,
  double width = 170,
  double height = 170,
}) {
  return SizedBox(
    width: width,
    height: height,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFF394A94),
              width: 5,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Nunito Sans',
                  color: Color(0xFF394A94),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}