import 'dart:io';

final home = Platform.environment['HOME'];

void main() {
  print('Listing repos...');
  final repos = Directory('$home/repos')
      .listSync(recursive: true)
      .whereType<Directory>()
      .where((e) => e.path.endsWith('.git'));

  for (final repo in repos) {
    final remoteOutput =
        Process.runSync('git', ['remote', '-v'], workingDirectory: repo.path)
            .stdout
            .toString();
    final httpsRemotes = RegExp(r'(.+?)\s+https:\/\/(.+?)\/(.+?)\/(.+?).git')
        .allMatches(remoteOutput)
        // Prevent duplicates
        .toSet()
        .map((e) => GitRemote(e[1]!, e[2]!, e[3]!, e[4]!))
        .toList();

    if (httpsRemotes.isEmpty) {
      print('No HTTPS remotes found for repo "${repo.path}"');
      continue;
    }

    for (final remote in httpsRemotes) {
      print(
        'Changing remote "${remote.name}" to SSH for repo "${repo.path}"...',
      );
      Process.runSync(
        'git',
        [
          'remote',
          'set-url',
          remote.name,
          'git@${remote.host}:${remote.owner}/${remote.repo}.git',
        ],
        workingDirectory: repo.path,
      );
    }
  }
}

class GitRemote {
  final String name;
  final String host;
  final String owner;
  final String repo;

  GitRemote(this.name, this.host, this.owner, this.repo);
}
