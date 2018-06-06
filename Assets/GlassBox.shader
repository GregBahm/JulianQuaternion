Shader "Unlit/GlassBox"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			Cull Off
			ZWrite Off
			Blend One One
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float uDist = abs(i.uv.x - .5) * 2;
				float vDist = abs(i.uv.y - .5) * 2;
				float dist = max(uDist, vDist);
				float antiDist = min(uDist, vDist);
				antiDist = pow(antiDist, 2);
				float outline = pow(dist, 50) * .5;
				if(dist > .99)
				{
					antiDist = .1;
				}
				float ret = outline * antiDist;
				return ret;
			}
			ENDCG
		}
	}
}
