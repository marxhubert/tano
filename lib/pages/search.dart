import 'package:flutter/material.dart';
import 'package:tano/application/search_view_model.dart';
import 'package:tano/config/l10n.dart';
import 'package:tano/domain/notes_repository.dart';
import 'package:tano/models/note.dart';
import 'package:tano/pages/edit.dart';
import 'package:tano/utils/action.dart';
import 'package:tano/utils/menu.dart';

class SearchPage extends StatefulWidget {
    const SearchPage({super.key, required this.repository});

    final NotesRepository repository;

    @override
    State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
    late final SearchViewModel _viewModel;
    final TextEditingController _searchFieldController = TextEditingController();

    @override
    void initState() {
        super.initState();
        _viewModel = SearchViewModel(repository: widget.repository);
        _viewModel.load();
    }

    @override
    void dispose() {
        _searchFieldController.dispose();
        _viewModel.dispose();
        super.dispose();
    }

    Future<void> _noteController({required Note note}) async {
        final NoteAction? result = await Navigator.push(
            context,
            MaterialPageRoute<NoteAction>(
                builder: (context) => EditNote(
                    add: false,
                    index: _viewModel.results.indexOf(note),
                    noteAction: NoteAction(action: '', note: note),
                    repository: widget.repository,
                ),
                fullscreenDialog: true
            ),
        );
        if (result == null) {
            return;
        }
        await _viewModel.applyNoteAction(original: note, action: result);
    }

    Widget _showSearchResult(List<Note> notes) {
        return Container(
            child: notes.isEmpty
            ? Column(children: <Widget>[
                Padding(padding: EdgeInsets.only(bottom: 4.5),),
                Text(
                    AppText.tr('no_item_found'),
                    style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 12.0
                    ),
                ),
            ],)
            : _compactListLayout(notes),
        );
    }

    Widget _compactListLayout(List<Note> notes) {
        return ListView.separated(
            itemCount: notes.length,
            itemBuilder: (BuildContext context, int index) {
                String title = notes[index].title ?? '';
                String date = notes[index].date.toString().substring(0, 10);
                final bool important = notes[index].important == true;
                return Row(
                    children: <Widget>[
                        Expanded(
                            flex: 1,
                            child: Card(
                                elevation: 0.6,
                                color: themeCategory(notes[index].category ?? 'none', false),
                                shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(0.0)),
                                ),
                                child: Container(
                                    margin: EdgeInsets.only(left: 2.7),
                                    color: themeCategory(notes[index].category ?? 'none', true),
                                    child: ListTile(
                                        contentPadding: EdgeInsets.symmetric(horizontal: 9.0,),
                                        title: Text(
                                            title,
                                            style: TextStyle(
                                                fontSize: 14.4,
                                                fontWeight: FontWeight.bold
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: Text(
                                            date,
                                            style: TextStyle(
                                                fontSize: 12.0,
                                                fontStyle: FontStyle.italic,
                                            ),
                                        ),
                                        trailing: Icon(
                                            important ? Icons.star : Icons.star_border,
                                            color: important ? Colors.orange : null,
                                            size: 18.0,
                                        ),
                                        onTap: () {
                                            _noteController(note: notes[index]);
                                        },
                                    ),
                                ),
                            ),
                        ),
                    ],
                );
            },
            separatorBuilder: (BuildContext context, int index) {
                return Padding(
                    padding: EdgeInsets.only(bottom: 0.0),
                );
            },
        );
    }

    @override
    Widget build(BuildContext context) {
        return ListenableBuilder(
            listenable: _viewModel,
            builder: (BuildContext context, Widget? child) {
                return Scaffold(
                    body: SafeArea(
                        child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 7.2),
                            margin: EdgeInsets.only(top: 4.5),
                            child: Column(
                                children: <Widget>[
                                    Container(
                                        height: 36.0,
                                        decoration: BoxDecoration(
                                            color: Colors.black12,
                                            borderRadius: BorderRadius.circular(54.0),
                                        ),
                                        child: Row(
                                            children: <Widget>[
                                                GestureDetector(
                                                    child: Container(
                                                        width: 54.0,
                                                        decoration: BoxDecoration(
                                                            borderRadius: BorderRadius.circular(54.0),
                                                        ),
                                                        child: Center(
                                                            child: Icon(Icons.arrow_back, size: 21.0,),
                                                        ),
                                                    ),
                                                    onTap: () => Navigator.pop(context),
                                                ),
                                                Expanded(
                                                    flex: 1,
                                                    child: TextField(
                                                        showCursor: true,
                                                        controller: _searchFieldController,
                                                        autofocus: true,
                                                        textInputAction: TextInputAction.next,
                                                        style: TextStyle(
                                                            fontWeight: FontWeight.w400,
                                                            fontSize: 14.4,
                                                        ),
                                                        decoration: InputDecoration(
                                                            hintText: AppText.tr('type_to_search'),
                                                            hintStyle: TextStyle(
                                                                color: Colors.grey.shade600
                                                            ),
                                                            border: InputBorder.none,
                                                        ),
                                                        onTap: () {
                                                            _viewModel.search(_searchFieldController.text);
                                                        },
                                                        onChanged: (String text) {
                                                            _viewModel.search(text);
                                                        },
                                                    ),
                                                ),
                                                _searchFieldController.text == ''
                                                ? Offstage()
                                                : GestureDetector(
                                                    child: Container(
                                                        width: 54.0,
                                                        decoration: BoxDecoration(
                                                            borderRadius: BorderRadius.circular(54.0),
                                                        ),
                                                        child: Center(
                                                            child: Icon(Icons.clear, size: 21.0,),
                                                        ),
                                                    ),
                                                    onTap: () {
                                                        setState(() {
                                                            _searchFieldController.clear();
                                                        });
                                                        _viewModel.search('');
                                                    },
                                                ),
                                            ],
                                        ),
                                    ),
                                    _viewModel.hasResults
                                    ? Container(
                                        padding: EdgeInsets.symmetric(vertical: 4.5),
                                        child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: <Widget>[
                                                Text(
                                                    _viewModel.resultCount == 1 ? AppText.tr('single_result', <String, String>{'count': '${_viewModel.resultCount}'}) : AppText.tr('results', <String, String>{'count': '${_viewModel.resultCount}'}),
                                                    style: TextStyle(
                                                        fontStyle: FontStyle.italic,
                                                        fontSize: 12.0
                                                    ),
                                                ),
                                            ],
                                        ),
                                    )
                                    : Offstage(),
                                    Expanded(
                                        child: Container(
                                            child: _showSearchResult(_viewModel.results),
                                        ),
                                    ),
                                ],
                            ),
                        ),
                    ),
                );
            },
        );
    }
}
