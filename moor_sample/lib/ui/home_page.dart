import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../data/moor_database.dart';
import 'widget/new_task_input_widget.dart';
import 'widget/new_tag_input.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool showCompleted = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      body: Column(
        children: [
          Expanded(child: _buildTaskList(context)),
          NewTaskInput(),
          NewTagInput(),
        ],
      ),
    );
  }

  StreamBuilder<List<TaskWithTag>> _buildTaskList(BuildContext context) {
    final dao = Provider.of<TaskDao>(context);

    return StreamBuilder(
      stream: dao.watchAllTasks(),
      builder: (context, AsyncSnapshot<List<TaskWithTag>> snapshot) {
        final tasks = snapshot.data ?? [];
        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (_, index) {
            final itemTask = tasks[index];

            return _buildListItem(itemTask, dao);
          },
        );
      },
    );
  }

  Widget _buildListItem(TaskWithTag itemTask, TaskDao dao) {
    return Slidable(
      actionPane: SlidableDrawerActionPane(),
      secondaryActions: [
        IconSlideAction(
          caption: 'Delete',
          color: Colors.red,
          icon: Icons.delete,
          onTap: () => dao.deleteTask(itemTask.task),
        ),
      ],
      child: CheckboxListTile(
        title: Text(itemTask.task.name),
        subtitle: Text(itemTask.task.dueDate?.toString() ?? 'No date'),
        value: itemTask.task.completed,
        onChanged: (newValue) {
          dao.updateTask(itemTask.task.copyWith(completed: newValue));
        },
      ),
    );
  }

  // Row _buildCompletedOnlySwitch() {
  //   return Row(
  //     children: [
  //       Text('Completed only'),
  //       Switch(
  //         value: showCompleted,
  //         activeColor: Colors.white,
  //         onChanged: (newValue) {
  //           setState(() {
  //             showCompleted = newValue;
  //           });
  //         },
  //       )
  //     ],
  //   );
  // }
}
