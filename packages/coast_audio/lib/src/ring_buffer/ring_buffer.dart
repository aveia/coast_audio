import 'dart:ffi';
import 'dart:math';

import 'package:coast_audio/coast_audio.dart';

class RingBuffer {
  RingBuffer({required this.capacity, required this.pBuffer, Memory? memory}) : memory = FfiMemory();

  final int capacity;
  final Pointer<Void> pBuffer;
  final Memory memory;

  int _head = 0;
  int _length = 0;

  int get length => _length;

  int write(Pointer<Void> pInput, int offset, int size) {
    final writeSize = min(capacity - _length, size);
    if (writeSize == 0) {
      return 0;
    }

    final pOffsetInput = Pointer<Void>.fromAddress(pInput.address + offset);
    final pTail = Pointer<Void>.fromAddress(pBuffer.address + (_head + _length) % capacity);
    final pWriteEnd = Pointer<Void>.fromAddress(pBuffer.address + (_head + _length + writeSize) % capacity);

    if (pTail.address <= pWriteEnd.address) {
      memory.copyMemory(pTail, pOffsetInput, writeSize);
    } else {
      final pEnd = Pointer<Void>.fromAddress(pBuffer.address + capacity);

      final firstWrite = pEnd.address - pTail.address;
      memory.copyMemory(pTail, pOffsetInput, firstWrite);

      final secondWrite = writeSize - firstWrite;
      memory.copyMemory(pBuffer, Pointer.fromAddress(pOffsetInput.address + firstWrite), secondWrite);
    }

    _length += writeSize;
    return writeSize;
  }

  int read(Pointer<Void> pOutput, int offset, int size, {bool advance = true}) {
    final readSize = min(size, _length);
    if (readSize == 0) {
      return 0;
    }

    final pOffsetOutput = Pointer<Void>.fromAddress(pOutput.address + offset);
    final pHead = Pointer<Void>.fromAddress(pBuffer.address + _head);
    final pEndRead = Pointer<Void>.fromAddress(pBuffer.address + ((_head + readSize) % capacity));

    if (pEndRead.address <= pHead.address) {
      final pEnd = Pointer<Void>.fromAddress(pBuffer.address + capacity);

      final firstRead = pEnd.address - pHead.address;
      memory.copyMemory(pOffsetOutput, pHead, firstRead);

      final secondRead = readSize - firstRead;
      memory.copyMemory(Pointer.fromAddress(pOffsetOutput.address + firstRead), pBuffer, secondRead);
    } else {
      memory.copyMemory(pOffsetOutput, pHead, readSize);
    }

    if (advance) {
      _head = (_head + readSize) % capacity;
      _length -= readSize;
    }
    return readSize;
  }

  int copyTo(RingBuffer output, {required bool advance}) {
    final readSize = min(output.capacity - output.length, _length);
    final pHead = Pointer<Void>.fromAddress(pBuffer.address + _head);
    final pEndRead = Pointer<Void>.fromAddress(pBuffer.address + ((_head + readSize) % capacity));

    if (pEndRead.address <= pHead.address) {
      final pEnd = Pointer<Void>.fromAddress(pBuffer.address + capacity);

      final firstRead = pEnd.address - pHead.address;
      output.write(pHead, 0, firstRead);

      final secondRead = readSize - firstRead;
      output.write(pBuffer, 0, secondRead);
    } else {
      output.write(pHead, 0, readSize);
    }

    if (advance) {
      _head = (_head + readSize) % capacity;
      _length -= readSize;
    }
    return readSize;
  }

  void clear() {
    _head = 0;
    _length = 0;
  }
}
