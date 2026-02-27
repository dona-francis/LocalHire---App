
import 'package:flutter/material.dart';
import 'step1.dart';
import 'step2.dart';
import 'step3.dart';
import 'step4.dart';
import 'step5.dart';
import 'step6.dart';

/// 🔥 Shared Job Model
class JobData {
  String title = "";
  String description = "";
  String locationType = "";
  String location = "";
  DateTime? date;
  int budget = 0;
}

class AddJobScreen extends StatefulWidget {
  const AddJobScreen({super.key});

  @override
  State<AddJobScreen> createState() => _AddJobScreenState();
}

class _AddJobScreenState extends State<AddJobScreen> {
  final PageController _controller = PageController();

  /// 🔥 Shared data object
  JobData jobData = JobData();

  int currentPage = 0;

  /// 👉 Go to next step
  void nextStep() {
    if (currentPage < 5) {
      setState(() {
        currentPage++;
      });

      _controller.animateToPage(
        currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// 👉 Go to previous step
  void previousStep() {
    if (currentPage > 0) {
      setState(() {
        currentPage--;
      });

      _controller.animateToPage(
        currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  /// 🚀 Final Submit
  void submitJob() {
    debugPrint("====== JOB DATA ======");
    debugPrint("Title: ${jobData.title}");
    debugPrint("Description: ${jobData.description}");
    debugPrint("Location Type: ${jobData.locationType}");
    debugPrint("Location: ${jobData.location}");
    debugPrint("Date: ${jobData.date}");
    debugPrint("Budget: ${jobData.budget}");

    // Later → send to backend here

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      /// 🔝 App Bar
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: previousStep,
        ),
        title: Text(
          "Add a Job - Step ${currentPage + 1} of 6",
          style: const TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),

      /// 📄 Steps
      body: PageView(
        controller: _controller,
        physics: const NeverScrollableScrollPhysics(),
        children: [

          Step1(
            onNext: nextStep,
            jobData: jobData,
          ),

          Step2(
            onNext: nextStep,
            jobData: jobData,
          ),

          Step3(
            onNext: nextStep,
            jobData: jobData,
          ),

          Step4(
            onNext: nextStep,
            jobData: jobData,
          ),

          Step5(
            onNext: nextStep,
            jobData: jobData,
          ),

          Step6(
            onNext:(){},
            jobData: jobData,
          ),
        ],
      ),
    );
  }
}