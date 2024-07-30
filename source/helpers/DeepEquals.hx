package helpers;
//https://github.com/Mahdrentys/Haxe-Deep-Equals

import Type;
import haxe.ds.StringMap;
import haxe.ds.IntMap;
import haxe.ds.EnumValueMap;
import haxe.ds.ObjectMap;
import haxe.ds.Vector;
using haxe.EnumTools.EnumValueTools;
using Reflect;
using Type;
using haxe.EnumTools.EnumValueTools;

class DeepEquals
{
    private static var handlers = new Map<String, Dynamic->Dynamic->Bool>();
    private static var initialized = false;

    inline private static function isClass(value:Dynamic):Bool
    {
        return Std.isOfType(value, Class);
    }

    inline private static function isEnum(value:Dynamic):Bool
    {
        return Std.isOfType(value, Enum);
    }

    public static function deepEquals(a:Dynamic, b:Dynamic, equalFunctions = true):Bool
    {
        if (!initialized) initialize();

        var aType = Type.typeof(a);
        var bType = Type.typeof(b);
        if (aType.getIndex() != bType.getIndex()) return false;
        var type = aType;
        
        if (a == b)
        {
            return true;
        }
        else if (type.match(TNull))
        {
            return true;
        }
        else if (isClass(a) && isClass(b))
        {
            return Type.getClassName(a) == Type.getClassName(b);
        }
        else if (isEnum(a) && isEnum(b))
        {
            return Type.getEnumName(a) == Type.getEnumName(b);
        }
        else if (type.match(TEnum(_)))
        {
            function getEnumName(value:ValueType):String
            {
                return Type.getEnumName(value.getParameters()[0]);
            }

            if (getEnumName(aType) != getEnumName(bType)) return false;
            if (EnumValueTools.getName(a) != EnumValueTools.getName(b)) return false;
            if (!deepEquals(EnumValueTools.getParameters(a), EnumValueTools.getParameters(b))) return false;
            return true;
        }
        else if (type.match(TFunction))
        {
            return equalFunctions;
        }
        else if (type.match(TObject))
        {
			var fieldSort = function(a:String, b:String):Int
			{
				if (a < b)
					return -1;
				if (a > b)
					return 1;
				return 0;
			}

			var aFields:Array<String> = a.fields();
			aFields.sort(fieldSort);

			var bFields:Array<String> = b.fields();
			bFields.sort(fieldSort);

            if (!deepEquals(aFields, bFields)) return false;

            for (field in a.fields())
            {
                if (!deepEquals(a.field(field), b.field(field))) return false;
            }

            return true;
        }
        else if (type.match(TClass(_)))
        {
            var aClass = cast(aType.getParameters()[0], Class<Dynamic>);
            var bClass = cast(bType.getParameters()[0], Class<Dynamic>);
            if (!deepEquals(aClass, bClass)) return false;

            if (handlers.exists(aClass.getClassName()))
            {
                return handlers[aClass.getClassName()](a, b);
            }

            var fields = aClass.getInstanceFields();
            fields = fields.filter(function(field:String):Bool
            {
                return !Type.typeof(a.getProperty(field)).match(TFunction);
            });

            for (field in fields)
            {
                if (!deepEquals(a.getProperty(field), b.getProperty(field))) return false;
            }

            return true;
        }

        return false;
    }

    public static function handle(type:Class<Dynamic>, func:Dynamic->Dynamic->Bool):Void
    {
        if (!initialized) initialize();
        handlers[type.getClassName()] = func;
    }

    public static function unHandle<T>(type:Class<T>):Void
    {
        if (!initialized) initialize();
        handlers.remove(type.getClassName());
    }

    private static function initialize():Void
    {
        initialized = true;

        handle(String, function(a:String, b:String):Bool
        {
            return a == b;
        });

        handle(Array, function(a:Array<Dynamic>, b:Array<Dynamic>):Bool
        {
            if (a.length != b.length) return false;

            for (i in 0...a.length)
            {
                if (!deepEquals(a[i], b[i])) return false;
            }

            return true;
        });

        /*handle(Vector, function(a:Vector<Dynamic>, b:Vector<Dynamic>):Bool
        {
            if (a.length != b.length) return false;

            for (i in 0...a.length)
            {
                if (!deepEquals(a[i], b[i])) return false;
            }

            return true;
        });*/

        function checkMap(a:Map<Dynamic, Dynamic>, b:Map<Dynamic, Dynamic>):Bool
        {
            var aKeys:Array<Dynamic> = [];
            var bKeys:Array<Dynamic> = [];

            for (key in a.keys())
            {
                aKeys.push(key);
            }

            for (key in b.keys())
            {
                bKeys.push(key);
            }

            if (!deepEquals(aKeys, bKeys)) return false;

            for (key in aKeys)
            {
                if (!deepEquals(a[key], b[key])) return false;
            }

            return true;
        }

        /*handle(Map, function(a:Map<Dynamic, Dynamic>, b:Map<Dynamic, Dynamic>):Bool
        {
            return checkMap(a, b);
        });*/

        handle(StringMap, function(a:StringMap<Dynamic>, b:StringMap<Dynamic>):Bool
        {
            var castedA:Map<Dynamic, Dynamic> = cast a;
            var castedB:Map<Dynamic, Dynamic> = cast b;
            return checkMap(castedA, castedB);
        });

        handle(IntMap, function(a:StringMap<Dynamic>, b:StringMap<Dynamic>):Bool
        {
            var castedA:Map<Dynamic, Dynamic> = cast a;
            var castedB:Map<Dynamic, Dynamic> = cast b;
            return checkMap(castedA, castedB);
        });

        handle(EnumValueMap, function(a:StringMap<Dynamic>, b:StringMap<Dynamic>):Bool
        {
            var castedA:Map<Dynamic, Dynamic> = cast a;
            var castedB:Map<Dynamic, Dynamic> = cast b;
            return checkMap(castedA, castedB);
        });

        handle(ObjectMap, function(a:StringMap<Dynamic>, b:StringMap<Dynamic>):Bool
        {
            var castedA:Map<Dynamic, Dynamic> = cast a;
            var castedB:Map<Dynamic, Dynamic> = cast b;
            return checkMap(castedA, castedB);
        });

        handle(Date, function(a:Date, b:Date):Bool
        {
            return a.getTime() == b.getTime();
        });
    }
}