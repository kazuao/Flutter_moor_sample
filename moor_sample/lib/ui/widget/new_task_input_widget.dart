import 'package:flutter/material.dart';
import 'package:moor_flutter/moor_flutter.dart';
import 'package:provider/provider.dart';

import '../../data/moor_database.dart';

class NewTaskInput extends StatefulWidget {
  NewTaskInput({Key key}) : super(key: key);

  @override
  _NewTaskInputState createState() => _NewTaskInputState();
}

class _NewTaskInputState extends State<NewTaskInput> {
  DateTime newTaskDate;
  Tag selectedTag;
  TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          _buildTextField(context),
          _buildDateButton(context),
          _buildTagSelector(context),
        ],
      ),
    );
  }

  Expanded _buildTextField(BuildContext context) {
    return Expanded(
      child: TextField(
        controller: controller,
        decoration: InputDecoration(hintText: 'Task Name'),
        onSubmitted: (inputName) {
          final dao = Provider.of<TaskDao>(context, listen: false);
          final task = TasksCompanion(
            name: Value(inputName),
            dueDate: Value(newTaskDate),
          );
          dao.insertTask(task);
          resetValuesAfterSubmit();
        },
      ),
    );
  }

  StreamBuilder<List<Tag>> _buildTagSelector(BuildContext context) {
    return StreamBuilder(
      stream: Provider.of<TagDao>(context).watchTags(),
      builder: (context, snapshot) {
        final tags = snapshot.data ?? [];

        DropdownMenuItem<Tag> dropdownFromTag(Tag tag) {
          return DropdownMenuItem(
            value: tag,
            child: Row(
              children: [
                Text(tag.name),
                SizedBox(width: 5),
                Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(tag.color),
                  ),
                )
              ],
            ),
          );
        }

        final dropdownMenuItems =
            tags.map((tag) => dropdownFromTag(tag)).toList()
              ..insert(
                0,
                DropdownMenuItem(
                  value: null,
                  child: Text('No Tag'),
                ),
              );

        return Expanded(
          child: DropdownButton(
            onChanged: (Tag tag) {
              setState(() {
                selectedTag = tag;
              });
            },
            isExpanded: true,
            value: selectedTag,
            items: dropdownMenuItems,
          ),
        );
      },
    );
  }

  IconButton _buildDateButton(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.calendar_today),
      onPressed: () async {
        newTaskDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2010),
          lastDate: DateTime(2050),
        );
      },
    );
  }

  void resetValuesAfterSubmit() {
    setState(() {
      newTaskDate = null;
      selectedTag = null;
      controller.clear();
    });
  }
}
