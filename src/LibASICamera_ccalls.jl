function ASIGetNumOfConnectedCameras()
    ccall((:ASIGetNumOfConnectedCameras, libASICamera2), Cint, ())
end

function ASIGetProductIDs(pPIDs)
    ccall((:ASIGetProductIDs, libASICamera2), Cint, (Ref{Cint},), pPIDs)
end

function ASIGetCameraProperty(pASICameraInfo, iCameraIndex)
    ccall((:ASIGetCameraProperty, libASICamera2), ASI_ERROR_CODE, (Ref{_ASI_CAMERA_INFO}, Cint), pASICameraInfo, iCameraIndex)
end

function ASIGetCameraPropertyByID(iCameraID, pASICameraInfo)
    ccall((:ASIGetCameraPropertyByID, libASICamera2), ASI_ERROR_CODE, (Cint, Ref{ASI_CAMERA_INFO}), iCameraID, pASICameraInfo)
end

function ASIOpenCamera(iCameraID)
    ccall((:ASIOpenCamera, libASICamera2), ASI_ERROR_CODE, (Cint,), iCameraID)
end

function ASIInitCamera(iCameraID)
    ccall((:ASIInitCamera, libASICamera2), ASI_ERROR_CODE, (Cint,), iCameraID)
end

function ASICloseCamera(iCameraID)
    ccall((:ASICloseCamera, libASICamera2), ASI_ERROR_CODE, (Cint,), iCameraID)
end

# ASI_ERROR_CODE ASIGetNumOfControls(int iCameraID, int * piNumberOfControls);
function ASIGetNumOfControls(iCameraID, piNumberOfControls::Ref{Cint})
    ccall((:ASIGetNumOfControls, libASICamera2), ASI_ERROR_CODE, (Cint, Ref{Cint}), iCameraID, piNumberOfControls)
end

function ASIGetControlCaps(iCameraID, iControlIndex, pControlCaps)
    ccall((:ASIGetControlCaps, libASICamera2), ASI_ERROR_CODE, (Cint, Cint, Ref{_ASI_CONTROL_CAPS}), iCameraID, iControlIndex, pControlCaps)
end

function ASIGetControlValue(iCameraID, ControlType, plValue::Ref{Clong}, pbAuto::Ref{ASI_BOOL})
    ccall((:ASIGetControlValue, libASICamera2), ASI_ERROR_CODE, (Cint, Cint, Ref{Clong}, Ref{ASI_BOOL}), iCameraID, ControlType, plValue, pbAuto)
end

function ASISetControlValue(iCameraID, ControlType, lValue, bAuto)
    ccall((:ASISetControlValue, libASICamera2), ASI_ERROR_CODE, (Cint, Cint, Clong, Cint), iCameraID, ControlType, lValue, bAuto)
end

function ASISetROIFormat(iCameraID, iWidth, iHeight, iBin, Img_type::ASI_IMG_TYPE)
    ccall((:ASISetROIFormat, libASICamera2), ASI_ERROR_CODE, (Cint, Cint, Cint, Cint, ASI_IMG_TYPE), iCameraID, iWidth, iHeight, iBin, Img_type)
end

function ASIGetROIFormat(iCameraID, piWidth::Ref{Cint}, piHeight::Ref{Cint}, piBin::Ref{Cint}, pImg_type::Ref{ASI_IMG_TYPE})
    ccall((:ASIGetROIFormat, libASICamera2), ASI_ERROR_CODE, (Cint, Ref{Cint}, Ref{Cint}, Ref{Cint}, Ref{ASI_IMG_TYPE}), iCameraID, piWidth, piHeight, piBin, pImg_type)
end

function ASISetStartPos(iCameraID, iStartX, iStartY)
    ccall((:ASISetStartPos, libASICamera2), ASI_ERROR_CODE, (Cint, Cint, Cint), iCameraID, iStartX, iStartY)
end

function ASIGetStartPos(iCameraID, piStartX::Ref{Cint}, piStartY::Ref{Cint})
    ccall((:ASIGetStartPos, libASICamera2), ASI_ERROR_CODE, (Cint, Ref{Cint}, Ref{Cint}), iCameraID, piStartX, piStartY)
end

function ASIGetDroppedFrames(iCameraID, piDropFrames)
    ccall((:ASIGetDroppedFrames, libASICamera2), ASI_ERROR_CODE, (Cint, Ref{Cint}), iCameraID, piDropFrames)
end

function ASIEnableDarkSubtract(iCameraID, pcBMPPath)
    ccall((:ASIEnableDarkSubtract, libASICamera2), ASI_ERROR_CODE, (Cint, Cstring), iCameraID, pcBMPPath)
end

function ASIDisableDarkSubtract(iCameraID)
    ccall((:ASIDisableDarkSubtract, libASICamera2), ASI_ERROR_CODE, (Cint,), iCameraID)
end

function ASIStartVideoCapture(iCameraID)
    ccall((:ASIStartVideoCapture, libASICamera2), ASI_ERROR_CODE, (Cint,), iCameraID)
end

function ASIStopVideoCapture(iCameraID)
    ccall((:ASIStopVideoCapture, libASICamera2), ASI_ERROR_CODE, (Cint,), iCameraID)
end

function ASIGetVideoData(iCameraID, pBuffer::T, lBuffSize, iWaitms) where T
    if T == Matrix{UInt8}
        ccall((:ASIGetVideoData, libASICamera2), ASI_ERROR_CODE, (Cint, Ref{Cuchar}, Clong, Cint), iCameraID, pBuffer, lBuffSize, iWaitms)
    elseif T == Matrix{UInt16}  # explicitly handle unsafe conversion from uint16 to uint8
        ccall((:ASIGetVideoData, libASICamera2), ASI_ERROR_CODE, (Cint, Ref{Cuchar}, Clong, Cint), iCameraID, Base.unsafe_convert(Ref{Cuchar}, pBuffer), lBuffSize, iWaitms)
    end
end

function ASIPulseGuideOn(iCameraID, direction)
    ccall((:ASIPulseGuideOn, libASICamera2), ASI_ERROR_CODE, (Cint, Cint), iCameraID, direction)
end

function ASIPulseGuideOff(iCameraID, direction)
    ccall((:ASIPulseGuideOff, libASICamera2), ASI_ERROR_CODE, (Cint, Cint), iCameraID, direction)
end

function ASIStartExposure(iCameraID, bIsDark)
    ccall((:ASIStartExposure, libASICamera2), ASI_ERROR_CODE, (Cint, Cint), iCameraID, bIsDark)
end

function ASIStopExposure(iCameraID)
    ccall((:ASIStopExposure, libASICamera2), ASI_ERROR_CODE, (Cint,), iCameraID)
end

function ASIGetExpStatus(iCameraID, pExpStatus)
    ccall((:ASIGetExpStatus, libASICamera2), ASI_ERROR_CODE, (Cint, Ref{ASI_EXPOSURE_STATUS}), iCameraID, pExpStatus)
end

function ASIGetDataAfterExp(iCameraID, pBuffer::T, lBuffSize) where T
    if T == Matrix{UInt8}
        ccall((:ASIGetDataAfterExp, libASICamera2), ASI_ERROR_CODE, (Cint, Ref{Cuchar}, Clong), iCameraID, pBuffer, lBuffSize)
    elseif T == Matrix{UInt16}  # explicitly handle unsafe conversion from uint16 to uint8
        ccall((:ASIGetDataAfterExp, libASICamera2), ASI_ERROR_CODE, (Cint, Ref{Cuchar}, Clong), iCameraID, Base.unsafe_convert(Ref{Cuchar}, pBuffer), lBuffSize)
    end
end

function ASIGetID(iCameraID, pID)
    ccall((:ASIGetID, libASICamera2), ASI_ERROR_CODE, (Cint, Ref{ASI_ID}), iCameraID, pID)
end

function ASISetID(iCameraID, ID)
    ccall((:ASISetID, libASICamera2), ASI_ERROR_CODE, (Cint, ASI_ID), iCameraID, ID)
end

function ASIGetGainOffset(iCameraID, pOffset_HighestDR, pOffset_UnityGain, pGain_LowestRN, pOffset_LowestRN)
    ccall((:ASIGetGainOffset, libASICamera2), ASI_ERROR_CODE, (Cint, Ref{Cint}, Ref{Cint}, Ref{Cint}, Ref{Cint}), iCameraID, pOffset_HighestDR, pOffset_UnityGain, pGain_LowestRN, pOffset_LowestRN)
end

function ASIGetSDKVersion()
    ccall((:ASIGetSDKVersion, libASICamera2), Cstring, ())
end

function ASIGetCameraSupportMode(iCameraID, pSupportedMode)
    ccall((:ASIGetCameraSupportMode, libASICamera2), ASI_ERROR_CODE, (Cint, Ref{_ASI_SUPPORTED_MODE}), iCameraID, pSupportedMode)
end

function ASIGetCameraMode(iCameraID, mode)
    ccall((:ASIGetCameraMode, libASICamera2), ASI_ERROR_CODE, (Cint, Ref{ASI_CAMERA_MODE}), iCameraID, mode)
end

function ASISetCameraMode(iCameraID, mode)
    ccall((:ASISetCameraMode, libASICamera2), ASI_ERROR_CODE, (Cint, ASI_CAMERA_MODE), iCameraID, mode)
end

function ASISendSoftTrigger(iCameraID, bStart)
    ccall((:ASISendSoftTrigger, libASICamera2), ASI_ERROR_CODE, (Cint, Cint), iCameraID, bStart)
end

function ASIGetSerialNumber(iCameraID, pSN)
    ccall((:ASIGetSerialNumber, libASICamera2), ASI_ERROR_CODE, (Cint, Ref{ASI_SN}), iCameraID, pSN)
end

function ASISetTriggerOutputIOConf(iCameraID, pin, bPinHigh, lDelay, lDuration)
    ccall((:ASISetTriggerOutputIOConf, libASICamera2), ASI_ERROR_CODE, (Cint, ASI_TRIG_OUTPUT_PIN, Cint, Clong, Clong), iCameraID, pin, bPinHigh, lDelay, lDuration)
end

function ASIGetTriggerOutputIOConf(iCameraID, pin, bPinHigh, lDelay, lDuration)
    ccall((:ASIGetTriggerOutputIOConf, libASICamera2), ASI_ERROR_CODE, (Cint, ASI_TRIG_OUTPUT_PIN, Ref{Cint}, Ref{Clong}, Ref{Clong}), iCameraID, pin, bPinHigh, lDelay, lDuration)
end
