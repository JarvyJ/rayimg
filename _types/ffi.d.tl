
local interface CData
end

local record libffi
    type CData = CData
    type CType = string | CData
    type CFunction = function<T is CData>(...: any): T
    type CNamespace = { string : function(...: any): CData }

    load:       function(string): { string : CFunction<CData> }
    cdef:       function(string)
    new:        function(CType, integer): CData
    new:	function(CType, ...: any): CData
    new:	function<T is CData>(CType, ...: any): T
    new:	function<T is CData>(CType): T
    typeof:     function(CType, ...: any): CFunction
    typeof:	function<T>(CType): CFunction<T>
    cast:       function(CType, ...: any): CType
    metatype:   function(CType, metatable): CFunction
    gc:         function(CData, function(CData)): CData
    sizeof:     function(CType, integer | nil): integer | nil
    alignof:    function(CType): integer
    offsetof:   function(CType, string): integer, integer | nil, integer | nil
    istype:     function(CType, any): boolean
    errno:      function(integer | nil): integer
    string:     function(CData, ?integer): string
    copy:       function(CData, CData, integer)
    copy:       function(CData, string)
    fill:       function(CData, integer, CData)
    abi:        function(string): boolean
    set:        function(function)

    C: CNamespace
end

return libffi
