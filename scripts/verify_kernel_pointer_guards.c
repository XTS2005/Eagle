#include <assert.h>
#include <stdint.h>
#include "../lara/kexploit/kernel_pointer_validation.h"

int main(void) {
    const uint64_t minimum = 0xFFFFFFDC00000000ULL;

    assert(!eagle_kernel_pointer_value_is_valid(0));
    assert(!eagle_kernel_pointer_value_is_valid(UINT64_MAX));
    assert(!eagle_kernel_pointer_value_is_valid(UINT64_MAX + 0x10ULL));
    assert(!eagle_kernel_pointer_value_is_valid(0x000000000000000FULL));
    assert(eagle_kernel_pointer_value_is_valid(0xFFFFFFDC12345678ULL));
    assert(eagle_kernel_pointer_value_is_valid(0xFFFFFE0012345678ULL));
    assert(!eagle_kernel_pointer_is_canonical(UINT64_MAX, minimum));
    assert(!eagle_kernel_pointer_is_canonical(minimum, minimum));
    assert(!eagle_kernel_pointer_is_canonical(0xFFFFFE0012345678ULL, minimum));
    assert(eagle_kernel_pointer_is_canonical(0xFFFFFFDC12345678ULL, minimum));
    return 0;
}
