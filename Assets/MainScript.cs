using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class MainScript : MonoBehaviour
{
    public Material CreamImageMat;
    private CommandBuffer command;

    private readonly List<CreamRenderer> creamRenderers = new List<CreamRenderer>();

    void Start ()
    {

        //int screenCopyID = Shader.PropertyToID("_ScreenCopyTexture");

        command = new CommandBuffer();
        command.Clear();
        //command.GetTemporaryRT(screenCopyID, -1, -1, 0, FilterMode.Bilinear);
        //command.Blit(BuiltinRenderTextureType.CurrentActive, screenCopyID);
        command.Blit(BuiltinRenderTextureType.CurrentActive, BuiltinRenderTextureType.CurrentActive, CreamImageMat);

        AddBuffer(Camera.main);

#if UNITY_EDITOR
        foreach (var sceneCamera in UnityEditor.SceneView.GetAllSceneCameras())
        {
            AddBuffer(sceneCamera);
        }
#endif
    }

    private void AddBuffer(Camera sceneCamera)
    {
        CreamRenderer creamRenderer = sceneCamera.gameObject.AddComponent<CreamRenderer>();
        creamRenderer.Initialize(command);
        creamRenderers.Add(creamRenderer);
    }
}

public class CreamRenderer : MonoBehaviour
{
    private Camera targetCamera;
    private CommandBuffer commandBuffer;

    private void Awake()
    {
        targetCamera = this.GetComponent<Camera>();
    }

    protected void OnDestroy()
    {
#if UNITY_EDITOR
        if (name == "SceneCamera")
        {
            // In the editor in a scene camera, removing the command buffer causes a noisy null reference exception. We haven't
            // figured out why, yet, but it seems safe enough to not remove the command buffer from the scene camera, so we'll bail
            // out early here to avoid the noise.
            return;
        }
#endif

        if (commandBuffer != null)
        {
            targetCamera.RemoveCommandBuffer(CameraEvent.BeforeForwardAlpha, commandBuffer);
        }
    }

    public void Initialize(CommandBuffer commandBuffer)
    {
        this.commandBuffer = commandBuffer;

        targetCamera.AddCommandBuffer(CameraEvent.BeforeForwardAlpha, this.commandBuffer);
    }
}