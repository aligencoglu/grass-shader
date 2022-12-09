using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GrassBender : MonoBehaviour
{
    [SerializeField] Material grassMaterial;

    // Update is called once per frame
    void Update()
    {
        grassMaterial.SetVector("_PlayerWorldPosition", transform.position);
    }
}
