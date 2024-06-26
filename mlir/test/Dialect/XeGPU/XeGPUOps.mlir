// RUN: mlir-opt %s | FileCheck %s
// Verify the printed output can be parsed.
// RUN: mlir-opt %s | mlir-opt | FileCheck %s
// Verify the generic form can be parsed.
// RUN: mlir-opt -mlir-print-op-generic %s | mlir-opt | FileCheck %s

// CHECK-LABEL: gpu.module @test {
gpu.module @test {
// CHECK: gpu.func @test_create_nd_tdesc_vc_1(%[[arg0:.*]]: memref<24x32xf32>) {
gpu.func @test_create_nd_tdesc_vc_1(%src: memref<24x32xf32>) {
  // CHECK: %[[REG:.*]] = xegpu.create_nd_tdesc %arg0[0, 0] : memref<24x32xf32> -> !xegpu.tensor_desc<8x16xf32>
  %1 = xegpu.create_nd_tdesc %src[0, 0] : memref<24x32xf32> -> !xegpu.tensor_desc<8x16xf32>
  gpu.return
}

// CHECK: gpu.func @test_create_nd_tdesc_vc_2(%[[arg0:.*]]: ui64, %[[arg1:.*]]: index, %[[arg2:.*]]: index, %[[arg3:.*]]: index, %[[arg4:.*]]: index) {
gpu.func @test_create_nd_tdesc_vc_2(%src: ui64, %w : index, %h : index, %x : index, %y : index) {
  //CHECK: %[[C:.*]] = arith.constant 1 : index
  %c1 = arith.constant 1 : index
  // CHECK: %[[REG:.*]] = xegpu.create_nd_tdesc %[[arg0]][%[[arg3]], %[[arg4]]], [%[[arg2]], %[[arg1]]], [%[[arg1]], %[[C]]] : ui64 -> !xegpu.tensor_desc<8x16xf32>
  %1 = xegpu.create_nd_tdesc %src[%x, %y], [%h, %w], [%w, %c1] : ui64 -> !xegpu.tensor_desc<8x16xf32>
  gpu.return
}

// CHECK: gpu.func @test_create_nd_tdesc_vc_3(%[[arg0:.*]]: memref<24x32xf32>) {
gpu.func @test_create_nd_tdesc_vc_3(%src: memref<24x32xf32>) {
  // CHECK: %[[REG:.*]] = xegpu.create_nd_tdesc %[[arg0]][0, 0] : memref<24x32xf32> -> !xegpu.tensor_desc<24x16xf32, #xegpu.tdesc_attr<array_length = 2 : i64>
  %1 = xegpu.create_nd_tdesc %src[0, 0] : memref<24x32xf32> -> !xegpu.tensor_desc<24x16xf32, #xegpu.tdesc_attr<array_length = 2>>
  gpu.return
}

// CHECK: gpu.func @test_prefetch_nd_vc(%[[arg0:.*]]: memref<24x32xf16>) {
gpu.func @test_prefetch_nd_vc(%src: memref<24x32xf16>) {
  // CHECK: %[[R0:.*]] = xegpu.create_nd_tdesc %[[arg0]][0, 0] : memref<24x32xf16> -> !xegpu.tensor_desc<8x16xf16>
  %1 = xegpu.create_nd_tdesc %src[0, 0] : memref<24x32xf16> -> !xegpu.tensor_desc<8x16xf16>
  // CHECK: xegpu.prefetch_nd %[[R0]] <{l1_hint = #xegpu.cache_hint<cached>, l2_hint = #xegpu.cache_hint<uncached>}> : !xegpu.tensor_desc<8x16xf16>
  xegpu.prefetch_nd %1 <{l1_hint = #xegpu.cache_hint<cached>, l2_hint = #xegpu.cache_hint<uncached>}>: !xegpu.tensor_desc<8x16xf16>
  gpu.return
}

// CHECK: func @test_load_nd_vc(%[[arg0:.*]]: memref<8x16xf16>) {
gpu.func @test_load_nd_vc(%src: memref<8x16xf16>) {
  // CHECK: %[[R0:.*]] = xegpu.create_nd_tdesc %arg0[0, 0] : memref<8x16xf16> -> !xegpu.tensor_desc<8x16xf16>
  %1 = xegpu.create_nd_tdesc %src[0, 0] : memref<8x16xf16> -> !xegpu.tensor_desc<8x16xf16>
  // CHECK: %[[R1:.*]] = xegpu.load_nd %[[R0]] <{l1_hint = #xegpu.cache_hint<cached>, l2_hint = #xegpu.cache_hint<uncached>, vnni_axis = 0 : i64}> : !xegpu.tensor_desc<8x16xf16> -> vector<4x16x2xf16>
  %2 = xegpu.load_nd %1 <{vnni_axis = 0, l1_hint = #xegpu.cache_hint<cached>, l2_hint = #xegpu.cache_hint<uncached>}>
       : !xegpu.tensor_desc<8x16xf16> -> vector<4x16x2xf16>
  gpu.return
}

// CHECK: func @test_store_nd_vc(%[[arg0:.*]]: memref<24x32xf16>) {
gpu.func @test_store_nd_vc(%dst: memref<24x32xf16>) {
  // CHECK: %[[C:.*]] = arith.constant dense<1.000000e+00> : vector<24x32xf16>
  %1 = arith.constant dense<1.0>: vector<24x32xf16>
  // CHECK: %[[R0:.*]] = xegpu.create_nd_tdesc %[[arg0]][0, 0] : memref<24x32xf16> -> !xegpu.tensor_desc<24x32xf16>
  %2 = xegpu.create_nd_tdesc %dst[0, 0] : memref<24x32xf16> -> !xegpu.tensor_desc<24x32xf16>
  // CHECK: xegpu.store_nd %[[C]], %[[R0]] <{l1_hint = #xegpu.cache_hint<write_back>, l2_hint = #xegpu.cache_hint<uncached>}> : vector<24x32xf16>, !xegpu.tensor_desc<24x32xf16>
  xegpu.store_nd %1, %2 <{l1_hint = #xegpu.cache_hint<write_back>, l2_hint = #xegpu.cache_hint<uncached>}>: vector<24x32xf16>, !xegpu.tensor_desc<24x32xf16>
  gpu.return
}

// CHECK: gpu.func @test_create_update_nd_tdesc_vc(%[[arg0:.*]]: memref<24x32xf32>) {
gpu.func @test_create_update_nd_tdesc_vc(%src: memref<24x32xf32>) {
  // CHECK: %[[REG:.*]] = xegpu.create_nd_tdesc %arg0[0, 0] : memref<24x32xf32> -> !xegpu.tensor_desc<8x16xf32>
  %1 = xegpu.create_nd_tdesc %src[0, 0] : memref<24x32xf32> -> !xegpu.tensor_desc<8x16xf32>
  // CHECK: %[[R1:.*]] = xegpu.update_nd_offset %[[REG]], [0, 16] : !xegpu.tensor_desc<8x16xf32>
  %2 = xegpu.update_nd_offset %1, [0, 16]: !xegpu.tensor_desc<8x16xf32>
  gpu.return
}

// CHECK: gpu.func @test_create_tdesc_vc(%[[arg0:.*]]: ui64) {
gpu.func @test_create_tdesc_vc(%src: ui64) {
  //CHECK: %[[R0:.*]] = xegpu.create_tdesc %arg0 [0, 8, 16, 24] {chunk_size = 2 : i64} : ui64 -> !xegpu.tensor_desc<4x2xf32, #xegpu.tdesc_attr<scattered = true>>
  %1 = xegpu.create_tdesc %src[0, 8, 16, 24] {chunk_size = 2} : ui64  -> !xegpu.tensor_desc<4x2xf32, #xegpu.tdesc_attr<scattered = true>>
  gpu.return
}

// CHECK: gpu.func @test_prefetch_vc(%[[arg0:.*]]: ui64) {
gpu.func @test_prefetch_vc(%src: ui64) {
  //CHECK: %[[R0:.*]] = xegpu.create_tdesc %arg0 [0, 8, 16, 24] {chunk_size = 2 : i64} : ui64 -> !xegpu.tensor_desc<4x2xf32, #xegpu.tdesc_attr<scattered = true>>
  %1 = xegpu.create_tdesc %src[0, 8, 16, 24] {chunk_size = 2} : ui64  -> !xegpu.tensor_desc<4x2xf32, #xegpu.tdesc_attr<scattered = true>>
  // CHECK: xegpu.prefetch %[[R0]] <{l1_hint = #xegpu.cache_hint<cached>, l2_hint = #xegpu.cache_hint<uncached>}> : !xegpu.tensor_desc<4x2xf32, #xegpu.tdesc_attr<scattered = true>>
  xegpu.prefetch %1 <{l1_hint = #xegpu.cache_hint<cached>, l2_hint = #xegpu.cache_hint<uncached>}>: !xegpu.tensor_desc<4x2xf32, #xegpu.tdesc_attr<scattered = true>> 
  gpu.return
}

// CHECK: gpu.func @test_load_gather_vc(%[[arg0:.*]]: ui64) {
gpu.func @test_load_gather_vc(%src: ui64) {
  //CHECK: %[[cst:.*]] = arith.constant dense<true> : vector<4xi1>
  %0 = arith.constant dense<1>: vector<4xi1>
  //CHECK: %[[R0:.*]] = xegpu.create_tdesc %arg0 [0, 8, 16, 24] {chunk_size = 2 : i64} : ui64 -> !xegpu.tensor_desc<4x2xf32, #xegpu.tdesc_attr<scattered = true>>
  %1 = xegpu.create_tdesc %src[0, 8, 16, 24] {chunk_size = 2} : ui64  -> !xegpu.tensor_desc<4x2xf32, #xegpu.tdesc_attr<scattered = true>>
  //CHECK: %[[R1:.*]] = xegpu.load %[[R0]], %[[cst]] <{l1_hint = #xegpu.cache_hint<cached>, l2_hint = #xegpu.cache_hint<uncached>}>
  //CHECK-SAME: !xegpu.tensor_desc<4x2xf32, #xegpu.tdesc_attr<scattered = true>>, vector<4xi1> -> vector<4x2xf32>
  %2 = xegpu.load %1, %0 <{l1_hint = #xegpu.cache_hint<cached>, l2_hint = #xegpu.cache_hint<uncached>}>
        : !xegpu.tensor_desc<4x2xf32, #xegpu.tdesc_attr<scattered = true>>, vector<4xi1> -> vector<4x2xf32>
  gpu.return
}

// CHECK: gpu.func @test_store_scatter_vc(%[[arg0:.*]]: ui64) {
gpu.func @test_store_scatter_vc(%src: ui64) {
  //CHECK: %[[c0:.*]] = arith.constant dense<true> : vector<4xi1>
  %0 = arith.constant dense<1>: vector<4xi1>
  //CHECK: %[[c1:.*]] = arith.constant dense<2.900000e+00> : vector<4x2xf32>
  %1 = arith.constant dense<2.9>: vector<4x2xf32>
  //CHECK: %[[R0:.*]] = xegpu.create_tdesc %arg0 [0, 8, 16, 24] {chunk_size = 2 : i64} : ui64 -> !xegpu.tensor_desc<4x2xf32, #xegpu.tdesc_attr<scattered = true>>
  %2 = xegpu.create_tdesc %src[0, 8, 16, 24] {chunk_size = 2} : ui64  -> !xegpu.tensor_desc<4x2xf32, #xegpu.tdesc_attr<scattered = true>>
  //CHECK: xegpu.store %[[c1]], %[[R0]], %[[c0]] <{l1_hint = #xegpu.cache_hint<write_back>, l2_hint = #xegpu.cache_hint<uncached>}>
  //CHECK-SAME: vector<4x2xf32>, !xegpu.tensor_desc<4x2xf32, #xegpu.tdesc_attr<scattered = true>>, vector<4xi1>
  xegpu.store %1, %2, %0 <{l1_hint = #xegpu.cache_hint<write_back>, l2_hint = #xegpu.cache_hint<uncached>}>
        : vector<4x2xf32>, !xegpu.tensor_desc<4x2xf32, #xegpu.tdesc_attr<scattered = true>>, vector<4xi1>
  gpu.return
}

// CHECK: gpu.func @test_create_update_tdesc_vc(%[[arg0:.*]]: ui64) {
gpu.func @test_create_update_tdesc_vc(%src: ui64) {
  //CHECK: %[[R0:.*]] = xegpu.create_tdesc %arg0 [0, 8, 16, 24] {chunk_size = 2 : i64} : ui64 -> !xegpu.tensor_desc<4x2xf32, #xegpu.tdesc_attr<scattered = true>>
  %1 = xegpu.create_tdesc %src[0, 8, 16, 24] {chunk_size = 2} : ui64  -> !xegpu.tensor_desc<4x2xf32, #xegpu.tdesc_attr<scattered = true>>
  //CHECK: %[[R1:.*]] = xegpu.update_offset %[[R0]], [32, 32, 32, 32] : !xegpu.tensor_desc<4x2xf32, #xegpu.tdesc_attr<scattered = true>>
  %2 = xegpu.update_offset %1, [32, 32, 32, 32] : !xegpu.tensor_desc<4x2xf32, #xegpu.tdesc_attr<scattered = true>>
  gpu.return
}

}