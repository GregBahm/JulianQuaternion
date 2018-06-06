using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FractalTransformBinding : MonoBehaviour
{
    public Material FractalMaterial;
	
	void Update ()
    {
        FractalMaterial.SetMatrix("_FractalTransform", transform.worldToLocalMatrix);
	}
}
