import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_app/core/widgets/loading_widget.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/category_entity.dart';
import '../providers/category_notifier.dart';

// CHUYỂN SANG STATEFUL WIDGET ĐỂ DÙNG CONTROLLER
class CategorySelector extends ConsumerStatefulWidget {
  final String userId;
  final CategoryType type;
  final Function(CategoryEntity) onSelected;

  const CategorySelector({
    super.key,
    required this.userId,
    required this.type,
    required this.onSelected,
  });

  @override
  ConsumerState<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends ConsumerState<CategorySelector> {
  // Controller để lấy text từ ô nhập
  final _textController = TextEditingController();

  /// Tránh hai lần gọi liên tiếp (Enter + icon, hoặc tap nhanh trong test).
  bool _addCategoryInProgress = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // Hàm xử lý thêm danh mục (Dùng chung cho cả nút Enter và nút +)
  Future<void> _handleAddCategory() async {
    if (_addCategoryInProgress) return;
    final name = _textController.text.trim();
    if (name.isEmpty) return;

    _addCategoryInProgress = true;
    try {
      final newCategory = CategoryEntity(
        id: const Uuid().v4(),
        name: name,
        type: widget.type,
        userId: widget.userId,
      );

      await ref.read(categoryNotifierProvider.notifier).addCategory(newCategory);

      if (!mounted) return;
      _textController.clear();
      FocusManager.instance.primaryFocus?.unfocus();
    } finally {
      _addCategoryInProgress = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoryNotifierProvider);

    // Filter categories theo Type
    List<CategoryEntity> filteredList = [];
    if (state is CategoryLoaded) {
      filteredList = state.categories.where((c) => c.type == widget.type).toList();
    }

    return Container(
      // SỬA LỖI: Chỉ dùng 1 padding duy nhất ở đây
      // Khi bàn phím hiện lên, bottom sheet cần đẩy lên theo -> dùng Padding bottom theo viewInsets
      padding: EdgeInsets.only(
        left: 16, 
        right: 16, 
        top: 16, 
        bottom: MediaQuery.of(context).viewInsets.bottom + 16
      ),
      height: 500, 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chọn danh mục',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Builder(
              builder: (context) {
                if (state is CategoryLoading) return const LoadingWidget();
                if (state is CategoryError) return Center(child: Text(state.message));
                
                if (filteredList.isEmpty) {
                  return const Center(child: Text('Chưa có danh mục nào. Hãy tạo mới!'));
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final category = filteredList[index];
                    return Stack(
                      children: [
                        // Main category card
                        InkWell(
                          onTap: () {
                            widget.onSelected(category);
                            Navigator.pop(context);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.withOpacity(0.3)),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              category.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        // Delete button overlay (top-right)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            icon: const Icon(Icons.close, size: 18, color: Colors.red),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () async {
                              // Show confirmation dialog
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Xóa danh mục?'),
                                  content: Text('Bạn có chắc muốn xóa "${category.name}"?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Hủy'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      child: const Text('Xóa'),
                                    ),
                                  ],
                                ),
                              );
                              
                              if (confirm == true) {
                                await ref.read(categoryNotifierProvider.notifier).deleteCategory(category.id, category.userId);
                              }
                            },
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          // Nút thêm danh mục
          TextField(
            controller: _textController, // Gắn controller vào đây
            decoration: InputDecoration(
              hintText: 'Nhập tên danh mục mới...',
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              suffixIcon: IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.blue, size: 32),
                // GỌI HÀM XỬ LÝ KHI BẤM NÚT (+)
                onPressed: _handleAddCategory, 
              ),
            ),
            // GỌI HÀM XỬ LÝ KHI BẤM ENTER
            onSubmitted: (_) => _handleAddCategory(),
          ),
        ],
      ),
    );
  }
}