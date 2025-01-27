using System.Reflection;
using System.Collections;

namespace System
{
	struct Enum
	{
		[NoShow(true)]
		public static int GetCount(Type type)
		{
			int count = 0;
			for (var field in type.GetFields())
			{
				if (field.IsEnumCase)
					count++;
			}
			return count;
		}

		[NoShow(true)]
		[Comptime(ConstEval=true)]
		public static int GetCount<T>() where T : Enum
		{
			return GetCount(typeof(T));
		}

		[NoShow(true)]
		public static int64 GetMinValue(Type type)
		{
			int64? minValue = null;
			for (var data in GetValues(type))
			{
				if (minValue == null)
					minValue = data;
				else
					minValue = Math.Min(minValue.Value, data);
			}
			return minValue.ValueOrDefault;
		}

		[NoShow(true)]
		[Comptime(ConstEval=true)]
		public static var GetMinValue<T>() where T : Enum
		{
			Compiler.SetReturnType(typeof(T));
			return GetMinValue(typeof(T));
		}

		[NoShow(true)]
		public static int64 GetMaxValue(Type type)
		{
			int64? maxValue = null;
			for (var data in GetValues(type))
			{
				if (maxValue == null)
					maxValue = data;
				else
					maxValue = Math.Max(maxValue.Value, data);
			}
			return maxValue ?? -1;
		}

		[NoShow(true)]
		[Comptime(ConstEval=true)]
		public static var GetMaxValue<T>() where T : Enum
		{
			Compiler.SetReturnType(typeof(T));
			return GetMaxValue(typeof(T));
		}

		[NoShow(true)]
		public static void EnumToString(Type type, String strBuffer, int64 iVal)
		{
			for (var (name, data) in GetEnumerator(type))
			{
				if (data == iVal)
				{
					strBuffer.Append(name);
					return;
				}
			}
			iVal.ToString(strBuffer);
		}

		[NoShow(true)]
		public static Result<int64> Parse(Type type, StringView str, bool ignoreCase = false)
		{
			for (var (name, data) in GetEnumerator(type))
			{
				if (str.Equals(name, ignoreCase))
					return .Ok(data);
				if (int64.Parse(str) case .Ok(let val) && val == data)
					return .Ok(data);
			}

			return .Err;
		}

		[NoShow(true)]
		public static Result<T> Parse<T>(StringView str, bool ignoreCase = false) where T : enum
		{
			[IgnoreErrors(true)]
			{
				return EnumParser<T>.Parse(str, ignoreCase);
			}
#unwarn
			return .Err;
		}

		[NoShow(true)]
		public static bool IsDefined(Type type, int64 value)
		{
			for (var data in GetValues(type))
			{
				if (data == value)
					return true;
			}

			return false;
		}

		[NoShow(true)]
		public static bool IsDefined<T>(T value) where T : Enum
			where T : enum
		{
			for (var data in GetValues<T>())
			{
				if (data == (.)value)
					return true;
			}

			return false;
		}

		[NoShow(true)]
		public static EnumEnumerator GetEnumerator(Type type)
		{
		    return .(type);
		}

		[NoShow(true)]
		public static EnumEnumerator<TEnum> GetEnumerator<TEnum>()
			where TEnum : enum
		{
		    return .();
		}

		[NoShow(true)]
		public static EnumValuesEnumerator GetValues(Type type)
		{
		    return .(type);
		}

		[NoShow(true)]
		public static EnumValuesEnumerator<TEnum> GetValues<TEnum>()
			where TEnum : enum
		{
		    return .();
		}

		[NoShow(true)]
		public static EnumNamesEnumerator GetNames(Type type)
		{
		    return .(type);
		}

		[NoShow(true)]
		public static EnumNamesEnumerator<TEnum> GetNames<TEnum>()
			where TEnum : enum
		{
		    return .();
		}

		[NoShow(true)]
		private struct EnumFieldsEnumerator
		{
			TypeInstance mTypeInstance;
			int32 mIdx;

			public this(Type type)
			{
			    mTypeInstance = type as TypeInstance;
			    mIdx = -1;
			}

			public void Reset() mut
			{
			    mIdx = -1;
			}

			public void Dispose()
			{
			}

			public bool MoveNext() mut
			{
				if (mTypeInstance == null)
					return false;

				TypeInstance.FieldData* fieldData = null;

				repeat
				{
					mIdx++;
					if (mIdx == mTypeInstance.[Friend]mFieldDataCount)
						return false;
					fieldData = &mTypeInstance.[Friend]mFieldDataPtr[mIdx];
				}
				while (!fieldData.mFlags.HasFlag(.EnumCase));

			    return true;
			}

			public FieldInfo Current
			{
			    get
			    {
					var fieldData = &mTypeInstance.[Friend]mFieldDataPtr[mIdx];
			        return FieldInfo(mTypeInstance, fieldData);
			    }
			}

			public int32 Index
			{
				get
				{
					return mIdx;
				}
			}

			public Result<FieldInfo> GetNext() mut
			{
				if (!MoveNext())
					return .Err;
				return Current;
			}
		}

		[NoShow(true)]
		public struct EnumEnumerator : EnumFieldsEnumerator, IEnumerator<(StringView name, int64 value)>
		{
			public this(Type type) : base(type)
			{
			}

			public new (StringView name, int64 value) Current
			{
				get
				{
					return ((.)base.Current.[Friend]mFieldData.[Friend]mName, *(int64*)&base.Current.[Friend]mFieldData.[Friend]mData);
				}
			}

			public new Result<(StringView name, int64 value)> GetNext() mut
			{
				if (!MoveNext())
					return .Err;
				return Current;
			}
		}

		[NoShow(true)]
		public struct EnumEnumerator<TEnum> : EnumFieldsEnumerator, IEnumerator<(StringView name, TEnum value)>
			where TEnum : enum
		{
			public this() : base(typeof(TEnum))
			{
			}

			public new (StringView name, TEnum value) Current
			{
				get
				{
					return ((.)base.Current.[Friend]mFieldData.[Friend]mName, (.)*(int64*)&base.Current.[Friend]mFieldData.[Friend]mData);
				}
			}

			public new Result<(StringView name, TEnum value)> GetNext() mut
			{
				if (!MoveNext())
					return .Err;
				return Current;
			}
		}

		[NoShow(true)]
		public struct EnumValuesEnumerator : EnumFieldsEnumerator, IEnumerator<int64>
		{
			public this(Type type) : base(type)
			{
			}

			public new int64 Current
			{
				get
				{
					return *(int64*)&base.Current.[Friend]mFieldData.[Friend]mData;
				}
			}

			public new Result<int64> GetNext() mut
			{
				if (!MoveNext())
					return .Err;
				return Current;
			}
		}

		[NoShow(true)]
		public struct EnumValuesEnumerator<TEnum> : EnumFieldsEnumerator, IEnumerator<TEnum>
			where TEnum : enum
		{
			public this() : base(typeof(TEnum))
			{
			}

			public new TEnum Current
			{
				get
				{
					return (.)*(int64*)&base.Current.[Friend]mFieldData.[Friend]mData;
				}
			}

			public new Result<TEnum> GetNext() mut
			{
				if (!MoveNext())
					return .Err;
				return Current;
			}
		}

		[NoShow(true)]
		public struct EnumNamesEnumerator : EnumFieldsEnumerator, IEnumerator<StringView>
		{
			public this(Type type) : base(type)
			{
			}

			public new StringView Current
			{
				get
				{
					return (.)base.Current.[Friend]mFieldData.[Friend]mName;
				}
			}

			public new Result<StringView> GetNext() mut
			{
				if (!MoveNext())
					return .Err;
				return Current;
			}
		}

		[NoShow(true)]
		public struct EnumNamesEnumerator<TEnum> : EnumFieldsEnumerator, IEnumerator<StringView>
			where TEnum : enum
		{
			public this() : base(typeof(TEnum))
			{
			}

			public new StringView Current
			{
				get
				{
					return (.)base.Current.[Friend]mFieldData.[Friend]mName;
				}
			}

			public new Result<StringView> GetNext() mut
			{
				if (!MoveNext())
					return .Err;
				return Current;
			}
		}
	}

	class EnumParser<T>
	{
		[OnCompile(.TypeInit), Comptime]
		public static void OnTypeInit()
		{
			String code = scope .();

			code.Append("public static Result<T> Parse(StringView str, bool ignoreCase = false)\n");
			code.Append("{\n");

			Type dscrType = typeof(int);
			int dscrOffset = 0;
			for (var fieldInfo in typeof(T).GetFields())
			{
				if (fieldInfo.Name == "$discriminator")
				{
					dscrOffset = fieldInfo.MemberOffset;
					dscrType = fieldInfo.FieldType;
				}
			}

			bool hadPayload = false;
			bool hadCases = false;

			for (var fieldInfo in typeof(T).GetFields())
			{
				if (var fieldTypeInst = fieldInfo.FieldType as TypeInstance)
				{
					if ((fieldTypeInst.IsTuple) && (fieldTypeInst.FieldCount > 0))
					{
						code.Append("\tT result = default;\n");
						hadPayload = true;
						break;
					}
				}
			}

			int caseIdx = 0;
			for (var fieldInfo in typeof(T).GetFields())
			{
				if (!fieldInfo.IsEnumCase)
					continue;

				if (var fieldTypeInst = fieldInfo.FieldType as TypeInstance)
				{
					hadCases = true;
					bool hasPayload = (fieldTypeInst.IsTuple) && (fieldTypeInst.FieldCount > 0);
					if (!hasPayload)
					{
						code.AppendF($"\tif (str.Equals(\"{fieldInfo.Name}\", ignoreCase))\n\t\treturn .Ok(.{fieldInfo.Name});\n");
					}
					else	
					{
						code.AppendF($"\tif (str.StartsWith(\"{fieldInfo.Name}(\", ignoreCase ? .OrdinalIgnoreCase : .Ordinal))\n\t{{\n");
						code.AppendF($"\t\t*({dscrType}*)((uint8*)&result + {dscrOffset}) = {fieldInfo.MemberOffset};\n");
						code.AppendF($"\t\tvar itr = Try!(EnumFields(str.Substring({fieldInfo.Name.Length+1})));\n");
						for (var tupField in fieldTypeInst.GetFields())
							code.AppendF($"\t\tTry!(ParseValue(ref itr, ref *({tupField.FieldType}*)((uint8*)&result + {tupField.MemberOffset})));\n");
						code.Append("\t\treturn result;\n");
						code.Append("\t}\n");
					}
				}

				caseIdx++;
			}

			if ((hadCases) && (!hadPayload))
			{
				Type underlyingType = typeof(T).UnderlyingType;
				if (underlyingType.Size < 4)
					underlyingType = typeof(int);
				code.AppendF($"\tif ({underlyingType}.Parse(str) case let .Ok(iVal))\n");
				code.Append("\t\treturn .Ok((.)iVal);\n");
			}

			code.Append("\treturn .Err;\n");
			code.Append("}\n");

			Compiler.EmitTypeBody(typeof(Self), code);
		}

		static Result<StringSplitEnumerator> EnumFields(StringView str)
		{
			var str;
			str.Trim();
			if (!str.EndsWith(')'))
				return .Err;
			str.RemoveFromEnd(1);
			return str.Split(',');
		}

		static Result<void> ParseValue<TValue>(ref StringSplitEnumerator itr, ref TValue value)
		{
			return .Err;
		}

		static Result<void> ParseValue<TValue>(ref StringSplitEnumerator itr, ref TValue value) where TValue : IParseable<TValue>
		{
			var str = Try!(itr.GetNext());
			str.Trim();
			value = Try!(TValue.Parse(str));
			return .Ok;
		}
	}
}