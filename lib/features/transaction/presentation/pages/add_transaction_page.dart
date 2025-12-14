import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_app/core/widgets/loading_widget.dart';
import 'package:finance_app/core/utils/currency_input_formatter.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/transaction_entity.dart';
import '../providers/transaction_notifier.dart';
import '../../../category/domain/entities/category_entity.dart';
import '../../../category/presentation/providers/category_notifier.dart';
import '../../../category/presentation/widgets/category_selector.dart';

class TransactionFormPage extends ConsumerStatefulWidget {
  final String userId;
  final TransactionEntity? transactionToEdit;

  const TransactionFormPage({
    super.key, 
    required this.userId,
    this.transactionToEdit,
  });

  @override
  ConsumerState<TransactionFormPage> createState() => _TransactionFormPageState();
}

class _TransactionFormPageState extends ConsumerState<TransactionFormPage> {
  late TextEditingController _amountController;
  late TextEditingController _titleController; // <--- MỚI
  late TextEditingController _noteController;
  late String _selectedCategoryName;
  late TransactionType _type;
  late DateTime _selectedDate;

  bool get isEditing => widget.transactionToEdit != null;

  @override
  void initState() {
    super.initState();
    final t = widget.transactionToEdit;
    
    _amountController = TextEditingController(text: t != null ? t.amount.toStringAsFixed(0) : '');
    _titleController = TextEditingController(text: t?.title ?? ''); // <--- MỚI
    _noteController = TextEditingController(text: t?.note ?? '');
    _selectedCategoryName = t?.category ?? '';
    _type = t?.type ?? TransactionType.expense;
    _selectedDate = t?.date ?? DateTime.now();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryNotifierProvider.notifier).fetchCategories(widget.userId);
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose(); // <--- MỚI
    _noteController.dispose();
    super.dispose();
  }

  void _showCategorySelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return CategorySelector(
          userId: widget.userId,
          type: _type == TransactionType.income ? CategoryType.income : CategoryType.expense,
          onSelected: (category) {
            setState(() {
              _selectedCategoryName = category.name;
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionNotifierProvider);

    ref.listen(transactionNotifierProvider, (prev, next) {
      if (next.isSuccess) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditing ? 'Đã cập nhật giao dịch' : 'Thêm giao dịch thành công')),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Sửa giao dịch' : 'Thêm giao dịch')),
      body: state.isLoading
          ? const LoadingWidget()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<TransactionType>(
                          title: const Text('Chi tiêu'),
                          value: TransactionType.expense,
                          groupValue: _type,
                          onChanged: isEditing ? null : (value) {
                            setState(() {
                              _type = value!;
                              _selectedCategoryName = '';
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<TransactionType>(
                          title: const Text('Thu nhập'),
                          value: TransactionType.income,
                          groupValue: _type,
                          onChanged: isEditing ? null : (value) {
                            setState(() {
                              _type = value!;
                              _selectedCategoryName = '';
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Số tiền', 
                      border: OutlineInputBorder(), 
                      suffixText: 'VNĐ',
                      hintText: '0',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      CurrencyInputFormatter(),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- Ô NHẬP TÊN GIAO DỊCH MỚI ---
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Tên giao dịch (VD: Phở bò, Lương...)', 
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  // --------------------------------

                  InkWell(
                    onTap: _showCategorySelector,
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Danh mục', border: OutlineInputBorder(), prefixIcon: Icon(Icons.category), suffixIcon: Icon(Icons.arrow_drop_down)),
                      child: Text(_selectedCategoryName.isEmpty ? 'Chọn danh mục' : _selectedCategoryName, style: TextStyle(color: _selectedCategoryName.isEmpty ? Colors.grey : Colors.black)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  ListTile(
                    title: Text('Ngày: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                    leading: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => _selectedDate = picked);
                    },
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(labelText: 'Ghi chú', border: OutlineInputBorder(), prefixIcon: Icon(Icons.note)),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Validate cả Title
                        if (_amountController.text.isEmpty || _selectedCategoryName.isEmpty || _titleController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập Tiền, Tên giao dịch và Danh mục')));
                          return;
                        }

                        // Parse amount (bỏ dấu chấm trước)
                        final amountText = _amountController.text.replaceAll('.', '');
                        final amount = double.tryParse(amountText) ?? 0;
                        
                        final transaction = TransactionEntity(
                          id: isEditing ? widget.transactionToEdit!.id : const Uuid().v4(),
                          userId: widget.userId,
                          amount: amount,
                          type: _type,
                          category: _selectedCategoryName,
                          title: _titleController.text, // <--- LƯU TITLE
                          date: _selectedDate,
                          note: _noteController.text,
                        );

                        if (isEditing) {
                          ref.read(transactionNotifierProvider.notifier).updateTransaction(transaction);
                        } else {
                          ref.read(transactionNotifierProvider.notifier).addTransaction(transaction);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(isEditing ? 'CẬP NHẬT' : 'LƯU GIAO DỊCH'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}