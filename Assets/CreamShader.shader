Shader "Unlit/CreamShader"
{
	Properties
	{
		_StaticTime("Static Time", float) = 0
		_BaseColor("Base Color", Color) = (1, 1, 1)
		_LightAColor("Light A Color", Color) = (1, 1, 1)
		_LightBColor("Light B Color", Color) = (1, 1, 1)
		_SpecColor("Spec Color", Color) = (1, 1, 1)
		_FrenelColor("Frenel Color", Color) = (1, 1, 1)
		_TestA("Test A", float) = 0
		_TestB("Test B", float) = 0
		_TestC("Test C", float) = 0
		_TestD("Test D", float) = 0
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			
			float _StaticTime;
			float3 _BaseColor;
			float3 _LightAColor;
			float3 _LightBColor;
			float3 _SpecColor;
			float3 _FrenelColor;
			float _TestA;
			float _TestB;
			float _TestC;
			float _TestD;

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

			float map( in float3 p, out float4 oTrap, in float4 c )
			{
				float4 z = float4(p,0.0);
				float md2 = 1.0;
				float mz2 = dot(z,z);

				float4 trap = float4(abs(z.xyz),dot(z,z));

				for( int i=0; i<11; i++ )
				{
					// |dz|^2 -> 4*|dz|^2
					md2 *= 4.0*mz2;
        
					// z -> z2 + c
					z = float4( z.x*z.x-dot(z.yzw,z.yzw),
							  2.0*z.x*z.yzw ) + c;

					trap = min( trap, float4(abs(z.xyz),dot(z,z)) );

					mz2 = dot(z,z);
					if(mz2>4.0) break;
				}
    
				oTrap = trap;

				return 0.25*sqrt(mz2/md2)*log(mz2);
			}
			
			// analytic normal for quadratic formula
			float3 calcNormal( in float3 p, in float4 c )
			{
				float4 z = float4(p,0.0);

				float4 dz0 = float4(1.0,0.0,0.0,0.0);
				float4 dz1 = float4(0.0,1.0,0.0,0.0);
				float4 dz2 = float4(0.0,0.0,1.0,0.0);
				float4 dz3 = float4(0.0,0.0,0.0,1.0);

  				for(int i=0;i<11;i++)
				{
					float4 mz = float4(z.x,-z.y,-z.z,-z.w);

					// derivative
					dz0 = float4(dot(mz,dz0),z.x*dz0.yzw+dz0.x*z.yzw);
					dz1 = float4(dot(mz,dz1),z.x*dz1.yzw+dz1.x*z.yzw);
					dz2 = float4(dot(mz,dz2),z.x*dz2.yzw+dz2.x*z.yzw);
					dz3 = float4(dot(mz,dz3),z.x*dz3.yzw+dz3.x*z.yzw);

					z = float4( dot(z, mz), 2.0*z.x*z.yzw ) + c;

					if( dot(z,z)>4.0 ) break;
				}

				return normalize(float3(dot(z,dz0),
									  dot(z,dz1),
									  dot(z,dz2)));
			}

			float intersect( in float3 ro, in float3 rd, out float4 res, in float4 c )
			{
				float4 tmp;
				float resT = -1.0;
				float maxd = 10.0;
				float h = 1.0;
				float t = 0.0;
				for( int i=0; i<150; i++ )
				{
					if( h<0.002||t>maxd ) break;
					h = map( ro+rd*t, tmp, c );
					t += h;
				}
				if( t<maxd ) { resT=t; res = tmp; }

				return resT;
			}
			
			float softshadow( in float3 ro, in float3 rd, float mint, float k, in float4 c )
			{
				float res = 1.0;
				float t = mint;
				for( int i=0; i<64; i++ )
				{
					float4 kk;
					float h = map(ro + rd*t, kk, c);
					res = min( res, k*h/t );
					if( res<0.001 ) break;
					t += clamp( h, 0.01, 0.5 );
				}
				return clamp(res,0.0,1.0);
			}
			
			float4 render( in float3 ro, in float3 rd, in float4 c )
			{
				float3 light1 = float3(  0.577, 0.577,  0.577 );
				float3 light2 = float3( -0.707, 0.000, -0.707 );

				float4 tra;
				float t = intersect( ro, rd, tra, c );
				if( t < 0.0 )
				{
					return 0;
				}

				float3 pos = ro + t*rd;
				float3 nor = calcNormal( pos, c );
				float3 ref = reflect( rd, nor );

				float dif1 = clamp( dot( light1, nor ), 0.0, 1.0 );
				float dif2 = clamp( 0.5 + 0.5*dot( light2, nor ), 0.0, 1.0 );
				float occ = clamp(2.5*tra.w-0.15,0.0,1.0);
				float sha = softshadow( pos, light1, 0.001, 64.0, c );
				float fre = pow( clamp( 1.+dot(rd,nor), 0.0, 1.0 ), 2.0 );

				//return dif1;
        
				float3 lin  = 0;
				lin += _LightAColor * dif1 * sha;
				lin += _LightBColor * dif2 * occ;
				lin += _FrenelColor * fre * (0.2 + 0.8  *occ);
				
				float specBase = pow( clamp( dot( ref, light1 ), 0.0, 1.0 ), 32.0 ) * dif1 * sha;

				float3 col = _BaseColor;
				col *= lin;
				col += _SpecColor * specBase;
				//col += 0.1*float3(0.8,0.9,1.0)*smoothstep( 0.0, 0.1, ref.y )*occ*(0.5+0.5*nor.y);

				col = pow(col, 0.4545);
				return float4(col, 1);
			}

			float4 mainImage(float2 fragCoord )
			{
				// anim
				//float time = _Time.x;
				float time = _StaticTime;
				float4 c = 0.4*cos( float4(0.5,3.9,1.4,1.1) + time*float4(1.2,1.7,1.3,2.5) ) - float4(0.3,0.0,0.0,0.0);

				// camera
				float r = 1;
				float3 ro = float3(_TestA, _TestB, _TestC);
				float3 ta = float3(0.0,0.0,0.0);
				float cr = _TestD;
    
    
				// render
				float3 cw = normalize(ta-ro);
				float3 cp = float3(sin(cr), cos(cr),0.0);
				float3 cu = normalize(cross(cw,cp));
				float3 cv = normalize(cross(cu,cw));
				float3 rd = normalize( fragCoord.x * cu + fragCoord.y * cv + 2.0 * cw );

				return render( ro, rd, c );
			}

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float4 col = mainImage(i.uv);
				clip(col.a - .5);
				return col;
			}
			ENDCG
		}
	}
}
