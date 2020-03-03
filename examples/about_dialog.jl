mutable struct DLGTEMPLATEEX
    dlgVer::Cushort
    signature::Cushort
    helpID::Culong
    exStyle::Culong
    style::Culong
    cDlgItems::Cushort
    x::Cshort
    y::Cshort
    cx::Cshort
    cy::Cshort
end

const DLGTEMPLATEEX_SIZE = 26

mutable struct DLGITEMTEMPLATEEX
    helpID::Culong
    exStyle::Culong
    style::Culong
    x::Cshort
    y::Cshort
    cx::Cshort
    cy::Cshort
    id::Culong
end

const BS_DEFPUSHBUTTON = convert(Culong, 0x00000001)
const BS_PUSHBUTTON = convert(Culong, 0x00000000)
const BS_GROUPBOX = convert(Culong, 0x00000007)

const WM_INITDIALOG = convert(Cuint, 0x0110)

const IDOK = 1

function create_about_dialog()
    dlgHeader = DLGTEMPLATEEX(
        1,
        0xffff,
        0,
        0,
        DS_MODALFRAME | WS_POPUP | WS_CAPTION | WS_SYSMENU,
        1,
        0,
        0,
        239,
        66
    )
    menu = [0x0000]
    class = [0x0000]
    title = [0x0000]
    dlgItem = DLGITEMTEMPLATEEX(
        0,
        0,
        BS_DEFPUSHBUTTON | WS_VISIBLE | WS_CHILD,
        174,
        18,
        50,
        14,
        IDOK
    )
    itemClass = [0xffff, 0x0080]
    itemTitle = "OK"
    extraCount = [0x0000]

    dwordsize = sizeof(UInt32)
    wordsize = sizeof(UInt16)
    headersize = DLGTEMPLATEEX_SIZE + sizeof(menu) + sizeof(class) + sizeof(title)
    padding = rem(headersize, dwordsize)
    remaindersize = sizeof(DLGITEMTEMPLATEEX) + sizeof(itemClass) + (sizeof(itemTitle) + 1) * wordsize + sizeof(extraCount)

    mem = zeros(UInt8, headersize + padding + remaindersize)
    mem_ptr = pointer(mem)

    dlgHeader_ptr = convert(Ptr{UInt8},pointer_from_objref(dlgHeader))
    unsafe_copyto!(mem_ptr, dlgHeader_ptr, DLGTEMPLATEEX_SIZE)
    mem_ptr += (headersize + padding)

    dlgItem_ptr = convert(Ptr{UInt8}, pointer_from_objref(dlgItem))
    unsafe_copyto!(mem_ptr, dlgItem_ptr, sizeof(DLGITEMTEMPLATEEX))
    mem_ptr += sizeof(DLGITEMTEMPLATEEX)

    unsafe_copyto!(mem_ptr, convert(Ptr{UInt8},pointer(itemClass)), sizeof(itemClass))
    mem_ptr += sizeof(itemClass)

    itemTitleCw = WinApi.cwstring(itemTitle)
    unsafe_copyto!(mem_ptr, convert(Ptr{UInt8}, convert(Ptr{UInt16}, itemTitleCw)), 3 * wordsize)

    mem
end
