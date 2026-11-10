import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/nguoi_dung.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/password_text.dart';
import '../../widgets/user_avatar.dart';
import '../profile_screen.dart';
import '../user_detail_screen.dart';
import '../user_form_screen.dart';

/// Module admin: danh sách người dùng + tìm kiếm, sắp xếp, thống kê, thêm/sửa/xoá.
/// Màn hình rộng (web) hiển thị dạng bảng, màn hình hẹp (di động) dạng danh sách thẻ.
class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<UserProvider>().load());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openForm({NguoiDung? user}) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserFormScreen(mode: user == null ? FormMode.create : FormMode.edit, user: user),
        ),
      );

  void _openDetail(NguoiDung user) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => UserDetailScreen(user: user)),
      );

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();
    final me = context.watch<AuthProvider>().user;
    final wide = MediaQuery.sizeOf(context).width >= 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý người dùng'),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: provider.loading ? null : provider.load,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Hồ sơ của tôi',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
            icon: me == null
                ? const Icon(Icons.account_circle)
                : UserAvatar(hinhanh: me.hinhanh, initials: me.initials, radius: 15),
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: () => logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Thêm người dùng'),
      ),
      body: RefreshIndicator(
        onRefresh: provider.load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    _StatsRow(stats: provider),
                    const SizedBox(height: 16),
                    _Toolbar(controller: _searchCtrl, provider: provider),
                    if (provider.loading) const LinearProgressIndicator(),
                    if (provider.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(provider.error!,
                            style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            if (!provider.loading && provider.users.isEmpty && provider.error == null)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('Không có người dùng nào')),
              )
            else if (wide)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                sliver: SliverToBoxAdapter(
                  child: _UserTable(
                    users: provider.users,
                    currentEmail: me?.email,
                    onView: _openDetail,
                    onEdit: (u) => _openForm(user: u),
                    onDelete: (u) => confirmDelete(context, u),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 96),
                sliver: SliverList.builder(
                  itemCount: provider.users.length,
                  itemBuilder: (context, i) {
                    final u = provider.users[i];
                    return _UserCard(
                      user: u,
                      isSelf: u.email == me?.email,
                      onTap: () => _openDetail(u),
                      onEdit: () => _openForm(user: u),
                      onDelete: () => confirmDelete(context, u),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final UserProvider stats;

  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final s = stats.stats;
    Widget tile(IconData icon, String label, int value, Color color) => Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$value', style: Theme.of(context).textTheme.titleLarge),
                        Text(label, style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        tile(Icons.people_alt_outlined, 'Tổng số', s.tongSo, scheme.primary),
        tile(Icons.image_outlined, 'Có ảnh', s.coAnh, Colors.green),
        tile(Icons.hide_image_outlined, 'Không ảnh', s.khongAnh, Colors.orange),
      ],
    );
  }
}

class _Toolbar extends StatelessWidget {
  final TextEditingController controller;
  final UserProvider provider;

  const _Toolbar({required this.controller, required this.provider});

  @override
  Widget build(BuildContext context) {
    final sortKey = '${provider.sortField.name}_${provider.desc ? 'desc' : 'asc'}';
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: TextField(
            controller: controller,
            onChanged: provider.setSearch,
            decoration: InputDecoration(
              hintText: 'Tìm theo họ tên hoặc email...',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              isDense: true,
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        controller.clear();
                        provider.setSearch('');
                      },
                    ),
            ),
          ),
        ),
        DropdownMenu<String>(
          width: 220,
          initialSelection: sortKey,
          label: const Text('Sắp xếp'),
          leadingIcon: const Icon(Icons.sort),
          onSelected: (v) {
            if (v == null) return;
            final parts = v.split('_');
            provider.setSort(SortField.values.byName(parts[0]), parts[1] == 'desc');
          },
          dropdownMenuEntries: const [
            DropdownMenuEntry(value: 'hoten_asc', label: 'Họ tên A → Z'),
            DropdownMenuEntry(value: 'hoten_desc', label: 'Họ tên Z → A'),
            DropdownMenuEntry(value: 'email_asc', label: 'Email A → Z'),
            DropdownMenuEntry(value: 'email_desc', label: 'Email Z → A'),
          ],
        ),
        Text('${provider.users.length} kết quả', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// Bảng hiển thị trên web / màn hình rộng: hinhanh, hoten, email, matkhau.
class _UserTable extends StatelessWidget {
  final List<NguoiDung> users;
  final String? currentEmail;
  final ValueChanged<NguoiDung> onView;
  final ValueChanged<NguoiDung> onEdit;
  final ValueChanged<NguoiDung> onDelete;

  const _UserTable({
    required this.users,
    required this.currentEmail,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
          showCheckboxColumn: false,
          dataRowMinHeight: 64,
          dataRowMaxHeight: 72,
          headingRowColor: WidgetStatePropertyAll(Theme.of(context).colorScheme.surfaceContainerHighest),
          columns: const [
            DataColumn(label: Text('Hình ảnh')),
            DataColumn(label: Text('Họ tên')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Mật khẩu')),
            DataColumn(label: Text('Thao tác')),
          ],
          rows: [
            for (final u in users)
              DataRow(
                onSelectChanged: (_) => onView(u),
                cells: [
                  DataCell(Hero(
                    tag: 'avatar-${u.email}',
                    child: UserAvatar(hinhanh: u.hinhanh, initials: u.initials, radius: 22),
                  )),
                  DataCell(Row(
                    children: [
                      Flexible(child: Text(u.hoten, overflow: TextOverflow.ellipsis)),
                      if (u.email == currentEmail) ...[
                        const SizedBox(width: 6),
                        const Chip(label: Text('Bạn'), visualDensity: VisualDensity.compact),
                      ],
                    ],
                  )),
                  DataCell(Text(u.email)),
                  DataCell(PasswordText(u.matkhau)),
                  DataCell(Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Xem',
                        onPressed: () => onView(u),
                        icon: const Icon(Icons.visibility_outlined),
                      ),
                      IconButton(
                        tooltip: 'Sửa',
                        onPressed: () => onEdit(u),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: u.email == currentEmail ? 'Không thể tự xoá' : 'Xoá',
                        onPressed: u.email == currentEmail ? null : () => onDelete(u),
                        icon: Icon(Icons.delete_outline,
                            color: u.email == currentEmail ? null : Theme.of(context).colorScheme.error),
                      ),
                    ],
                  )),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Thẻ người dùng trên di động; vuốt sang trái để xoá.
class _UserCard extends StatelessWidget {
  final NguoiDung user;
  final bool isSelf;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final Future<bool> Function() onDelete;

  const _UserCard({
    required this.user,
    required this.isSelf,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final card = Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Hero(
          tag: 'avatar-${user.email}',
          child: UserAvatar(hinhanh: user.hinhanh, initials: user.initials, radius: 26),
        ),
        title: Text(isSelf ? '${user.hoten} (bạn)' : user.hoten, overflow: TextOverflow.ellipsis),
        subtitle: Text(user.email, overflow: TextOverflow.ellipsis),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'edit') onEdit();
            if (v == 'delete') onDelete();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Sửa'))),
            PopupMenuItem(
              value: 'delete',
              enabled: !isSelf,
              child: const ListTile(leading: Icon(Icons.delete_outline), title: Text('Xoá')),
            ),
          ],
        ),
      ),
    );
    if (isSelf) return card;
    return Dismissible(
      key: ValueKey(user.email),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(color: scheme.error, borderRadius: BorderRadius.circular(12)),
        child: Icon(Icons.delete, color: scheme.onError),
      ),
      child: card,
    );
  }
}
