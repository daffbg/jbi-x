"""
SelectionVector identifies active rows without materializing
a new filtered batch.
"""
struct SelectionVector
    mask::BitVector
end

selected_count(selection::SelectionVector) =
    count(selection.mask)
