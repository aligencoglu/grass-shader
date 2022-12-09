using System.Collections;
using System.Collections.Generic;
using UnityEngine;

// DO NOT USE THIS - USE THE PARTICLE SYSTEM INSTEAD TO GENERATE GRASS
public class GrassGenerator : MonoBehaviour
{
    [SerializeField] Vector2 area = new Vector2(8.88f, 5f);
    [SerializeField] GameObject grassPrefab;
    [SerializeField] int grassBladeAmount = 1000;
    void Awake() {
        for (int i = 0; i < grassBladeAmount; i++) {
            Vector3 grassBladePos = new Vector3(Random.Range(-area.x, area.x),
                                                Random.Range(-area.y, area.y),
                                                transform.position.z);
            
            grassBladePos.z += grassBladePos.y;

            GameObject grassBlade = Instantiate(grassPrefab, grassBladePos, Quaternion.identity, transform);
            grassBlade.name = "GrassBlade_" + i;
        }
    }
}
