import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/pdf_service.dart';
import '../../../services/image_service.dart';
import '../models/image_item.dart';

// ------- State -------
enum ConversionStatus { idle, converting, done, error }

class ImageToPdfState extends Equatable {
  final List<ImageItem> images;
  final ConversionStatus status;
  final String? outputPath;
  final String? errorMessage;

  const ImageToPdfState({
    this.images = const [],
    this.status = ConversionStatus.idle,
    this.outputPath,
    this.errorMessage,
  });

  ImageToPdfState copyWith({
    List<ImageItem>? images,
    ConversionStatus? status,
    String? outputPath,
    String? errorMessage,
  }) =>
      ImageToPdfState(
        images: images ?? this.images,
        status: status ?? this.status,
        outputPath: outputPath ?? this.outputPath,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  @override
  List<Object?> get props =>
      [images, status, outputPath, errorMessage];
}

// ------- Cubit -------
class ImageToPdfCubit extends Cubit<ImageToPdfState> {
  final _picker = ImagePicker();

  ImageToPdfCubit() : super(const ImageToPdfState());

  void loadImages(List<ImageItem> items) {
    emit(state.copyWith(images: items));
  }

  Future<void> pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 90);
    if (picked.isEmpty) return;
    final newItems = picked.map((f) => ImageItem.fromPath(f.path)).toList();
    emit(state.copyWith(images: [...state.images, ...newItems]));
  }

  Future<void> pickFromCamera() async {
    final picked = await _picker.pickImage(
        source: ImageSource.camera, imageQuality: 90);
    if (picked == null) return;
    emit(state.copyWith(
        images: [...state.images, ImageItem.fromPath(picked.path)]));
  }

  void reorderImages(int oldIndex, int newIndex) {
    final list = List<ImageItem>.from(state.images);
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    emit(state.copyWith(images: list));
  }

  void removeImage(String id) {
    emit(state.copyWith(
        images: state.images.where((i) => i.id != id).toList()));
  }

  Future<void> rotateImage(String id, int degrees) async {
    final index = state.images.indexWhere((i) => i.id == id);
    if (index < 0) return;
    final item = state.images[index];
    final newPath = await ImageService.rotateImage(item.path, degrees);
    final newRotation = (item.rotation + degrees) % 360;
    final updated = item.copyWith(path: newPath, rotation: newRotation);
    final list = List<ImageItem>.from(state.images)..[index] = updated;
    emit(state.copyWith(images: list));
  }

  void updateItem(ImageItem updatedItem) {
    final list = state.images.map((i) {
      return i.id == updatedItem.id ? updatedItem : i;
    }).toList();
    emit(state.copyWith(images: list));
  }

  Future<void> convertToPdf() async {
    if (state.images.isEmpty) return;
    emit(state.copyWith(status: ConversionStatus.converting));
    try {
      final outputPath = await PdfService.convertImagesToPdf(state.images);
      emit(state.copyWith(
          status: ConversionStatus.done, outputPath: outputPath));
    } catch (e) {
      emit(state.copyWith(
          status: ConversionStatus.error, errorMessage: e.toString()));
    }
  }

  void reset() => emit(const ImageToPdfState());
}
