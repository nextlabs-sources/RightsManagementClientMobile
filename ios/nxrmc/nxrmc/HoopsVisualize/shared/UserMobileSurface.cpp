#include "UserMobileSurface.h"
#include "dprintf.h"

static UserMobileSurface		*g_surface;

// Users must implement createMobileSurface() to return a pointer to their derived MobileSurface
// Only one surface is created is created in the sandbox apps.
MobileSurface *createMobileSurface(int guiSurfaceId)
{
	// Create surface if necessary
	if (g_surface == 0)
		g_surface = new UserMobileSurface();

	return g_surface;
}

UserMobileSurface::UserMobileSurface()
	:  displayResourceMonitor(false), currentRenderingMode(HPS::Rendering::Mode::Default), frameRateEnabled(false)
{
}

UserMobileSurface::~UserMobileSurface()
{
}

bool UserMobileSurface::bind(void *window)
{
	// Perform surface init code here.
	// Note that we check if the Canvas is invalid before calling the base.
	// This is because the base bind() method creates a canvas.
	bool status;
	if (GetCanvas().Type() == HPS::Type::None)
	{
		status = MobileSurface::bind(window);
		
		// Setup scene startup values
		SetupSceneDefaults();
	}
	else
		status = MobileSurface::bind(window);

	GetCanvas().Update();
	return status;
}

void UserMobileSurface::singleTap(int x, int y)
{
	MobileSurface::singleTap(x, y);
	//dprintf("Single tap: %d %d\n", x, y);
}

void UserMobileSurface::doubleTap(int x, int y, HPS::TouchID id)
{
	MobileSurface::doubleTap(x, y, id);
	InjectTouchEvent(HPS::TouchEvent::Action::TouchDown, 1, &x, &y, &id, 2);
}

void UserMobileSurface::SetupSceneDefaults()
{
	HPS::View				view = GetCanvas().GetFrontView();
    view.GetOperatorControl().Push(new HPS::ZoomFitTouchOperator()).Push(new HPS::PanOrbitZoomOperator());
}

void UserMobileSurface::SetMainDistantLight(HPS::Vector const & lightDirection)
{
    HPS::DistantLightKit    light;
    light.SetDirection(lightDirection);
    light.SetCameraRelative(true);
    SetMainDistantLight(light);
}

void UserMobileSurface::SetMainDistantLight(HPS::DistantLightKit const & light)
{
    // Delete previous light before inserting new one
	if (mainDistantLight.Type() != HPS::Type::None)
		mainDistantLight.Delete();
	mainDistantLight = GetCanvas().GetFrontView().GetSegmentKey().InsertDistantLight(light);
}

bool UserMobileSurface::importHSFFile(const char * filename, HPS::Model const & model, HPS::Stream::ImportResultsKit & importResults)
{
    HPS::IOResult			status = HPS::IOResult::Failure;
	HPS::Stream::ImportNotifier     notifier;
    
	// HPS::Stream::File::Import can throw HPS::Stream::IOException
	try
	{
		// Specify the model segment as the segment to import to
		HPS::Stream::ImportOptionsKit			ioOpts;
		ioOpts.SetSegment(model.GetSegmentKey());
        
		// Initiate import and wait.  Import is done on a separate thread.
		notifier = HPS::Stream::File::Import(filename, ioOpts);
		notifier.Wait();
        
		status = notifier.Status();
	}
	catch (HPS::IOException const & ex)
	{
		status = ex.result;
	}

	if (status != HPS::IOResult::Success)
		return false;

	importResults = notifier.GetResults();
	return true;
}

bool UserMobileSurface::importSTLFile(const char * filename, HPS::Model const & model)
{
	HPS::IOResult			status = HPS::IOResult::Failure;

	HPS::STL::ImportNotifier notifier;
	// HPS::Stream::File::Import can throw HPS::Stream::IOException
	try
	{
		// Specify the model segment as the segment to import to
		HPS::STL::ImportOptionsKit			ioOpts;
		ioOpts.SetSegment(model.GetSegmentKey());

		// Initiate import and wait.  Import is done on a separate thread.
		notifier = HPS::STL::File::Import(HPS::UTF8(filename).GetBytes(), ioOpts);
		notifier.Wait();

		status = notifier.Status();
	}
	catch (HPS::IOException const & ex)
	{
		status = ex.result;
	}

	if (status != HPS::IOResult::Success)
		return false;

	return true;
}

bool UserMobileSurface::importOBJFile(const char * filename, HPS::Model const & model)
{
	HPS::IOResult			status = HPS::IOResult::Failure;

	HPS::OBJ::ImportNotifier notifier;
	// HPS::Stream::File::Import can throw HPS::Stream::IOException
	try
	{
		// Specify the model segment as the segment to import to
		HPS::OBJ::ImportOptionsKit			ioOpts;
		ioOpts.SetSegment(model.GetSegmentKey());

		// Initiate import and wait.  Import is done on a separate thread.
		notifier = HPS::OBJ::File::Import(HPS::UTF8(filename).GetBytes(), ioOpts);
		notifier.Wait();

		status = notifier.Status();
	}
	catch (HPS::IOException const & ex)
	{
		status = ex.result;
	}

	if (status != HPS::IOResult::Success)
		return false;

	return true;
}

#ifdef USING_EXCHANGE

bool UserMobileSurface::importPRCFile(const char * filename)
{
    HPS::IOResult			status = HPS::IOResult::Failure;
    
    HPS::Exchange::ImportNotifier notifier;
    // HPS::Stream::File::Import can throw HPS::Stream::IOException
    try
    {
        // Specify the prc import info
        HPS::Exchange::ImportOptionsKit			ioOpts;
        ioOpts.SetBRepMode(HPS::Exchange::BRepMode::BRepAndTessellation);
        
        // Initiate import and wait.  Import is done on a separate thread.
        notifier = HPS::Exchange::File::Import(HPS::UTF8(filename).GetBytes(), ioOpts);
        notifier.Wait();
        
        status = notifier.Status();
        
        if (status == HPS::IOResult::Success)
        {
            HPS::Exchange::CADModel model = notifier.GetCADModel();
            HPS::View view = model.ActivateDefaultCapture();
            GetCanvas().AttachViewAsLayout(view);
        }
    }
    catch (HPS::IOException const & ex)
    {
        status = ex.result;
    }
    
    return status == HPS::IOResult::Success;
}

bool UserMobileSurface::importU3DFile(const char * filename)
{
    HPS::IOResult			status = HPS::IOResult::Failure;
    
    HPS::Exchange::ImportNotifier notifier;
    // HPS::Stream::File::Import can throw HPS::Stream::IOException
    try
    {
        // Specify the u3d import info
        HPS::Exchange::ImportOptionsKit			ioOpts;
        
        // Initiate import and wait.  Import is done on a separate thread.
        notifier = HPS::Exchange::File::Import(HPS::UTF8(filename).GetBytes(), ioOpts);
        notifier.Wait();
        
        status = notifier.Status();
        
        if (status == HPS::IOResult::Success)
        {
            HPS::Exchange::CADModel model = notifier.GetCADModel();
            HPS::View view = model.ActivateDefaultCapture();
            GetCanvas().AttachViewAsLayout(view);
        }
    }
    catch (HPS::IOException const & ex)
    {
        status = ex.result;
    }
    
    return status == HPS::IOResult::Success;

}

#endif

bool UserMobileSurface::loadFile(const char* fileName)
{
	HPS::View			view = GetCanvas().GetFrontView();
	HPS::Model			model = view.GetAttachedModel();

	// Create a new model which we will import our scene into
	if (model.Type() != HPS::Type::None)
		model.Delete();
	model = HPS::Factory::CreateModel();

    HPS::Stream::ImportResultsKit stream_results;
    
    char const * tmp = strrchr(fileName, '.');
    if (tmp == nullptr)
        return false;
    
    char ext[5] = "";
    size_t length = strlen(tmp);
    for (int i = 0; i < length; ++i)
        ext[i] = static_cast<char>(tolower(tmp[i]));
    ext[length] = '\0';
    
    if (!strcmp(ext, ".hsf"))
        importHSFFile(fileName, model, stream_results);
    else if (!strcmp(ext, ".stl"))
        importSTLFile(fileName, model);
    else if (!strcmp(ext, ".obj"))
        importOBJFile(fileName, model);
#ifdef USING_EXCHANGE
    else if (!strcmp(ext, ".u3d"))
        importU3DFile(fileName);
    else if (!strcmp(ext, ".prc"))
        importPRCFile(fileName);
#endif
    else
        return false;
    
    // Enable static model for better performance
    model.GetSegmentKey().GetPerformanceControl().SetStaticModel(HPS::Performance::StaticModel::AttributeStaticModel);
    
    // Attach the model created in CHPSDoc
    view.AttachModel(model);
    
    // Add a distant light
    SetMainDistantLight();
    
    // Load default camera if we have one else fit world and do an update
	HPS::CameraKit defaultCamera;
	if (strcmp(ext, ".hsf") == 0 && stream_results.ShowDefaultCamera(defaultCamera))
	{
		view.GetSegmentKey().SetCamera(defaultCamera);
		view.Update();
	}
	else
		view.FitWorld();

    removecuttingSection();
	GetCanvas().UpdateWithNotifier().Wait();

	return true;
}

void UserMobileSurface::segControlValueChanged(long index)
{
    if (index == 2) {
        addcuttingSection();
    } else {
        removecuttingSection();
    }
}

void UserMobileSurface::insertcuttingSectonPlane(int index)
{
    if (cuttingOperatorPtr == nullptr) {
        addcuttingSection();
    }
    HPS::CameraKit cameraKit;
    GetCanvas().GetFrontView().GetSegmentKey().ShowCamera(cameraKit);
    HPS::Point target;
    cameraKit.ShowTarget(target);
    
    HPS::Plane plane;
    switch (index) {
        case 0:
        {
            float x = -fabs(target.x);
            plane = HPS::Plane(1, 0, 0, x);
        }
            break;
        case 1:
        {
            float y = -fabs(target.y);
            plane = HPS::Plane(0, 1, 0, y);
        }
            break;
        case 2:
        {
            float z = -fabs(target.z);
            plane = HPS::Plane(0, 0, 1, z);
        }
            break;
        default:
            break;
    }
    cuttingOperatorPtr->InsertCuttingPlaneFromEquation(plane);
    GetCanvas().Update();
}

void UserMobileSurface::removecuttingSection()
{
    if (cuttingOperatorPtr) {
        GetCanvas().GetFrontView().GetOperatorControl().Pop(HPS::Operator::Priority::High);
        cuttingOperatorPtr = nullptr;
        GetCanvas().GetFrontView().Update();
    }
}

void UserMobileSurface::addcuttingSection()
{
    if (cuttingOperatorPtr == nullptr) {
        cuttingOperatorPtr =  new HPS::CuttingSectionOperator();
        HPS::MaterialMappingKit mappingKit = cuttingOperatorPtr->GetPlaneMaterial();
        mappingKit.SetCutFaceAlpha(1);
        mappingKit.SetCutEdgeColor(HPS::RGBAColor(0, 0, 0, 0));
        cuttingOperatorPtr->SetPlaneMaterial(mappingKit);
        GetCanvas().GetFrontView().GetOperatorControl().Push(cuttingOperatorPtr, HPS::Operator::Priority::High);
    }
}

void UserMobileSurface::setOperatorOrbit()
{
	GetCanvas().GetFrontView().GetOperatorControl().Pop();
	GetCanvas().GetFrontView().GetOperatorControl().Push(new HPS::PanOrbitZoomOperator());
}

void UserMobileSurface::setOperatorZoomArea()
{
	GetCanvas().GetFrontView().GetOperatorControl().Pop();
	GetCanvas().GetFrontView().GetOperatorControl().Push(new HPS::ZoomBoxOperator());
}

void UserMobileSurface::setOperatorFly()
{
	GetCanvas().GetFrontView().GetOperatorControl().Pop();
	GetCanvas().GetFrontView().GetOperatorControl().Push(new HPS::FlyOperator());
}

void UserMobileSurface::setOperatorSelectPoint()
{
	GetCanvas().GetFrontView().GetOperatorControl().Pop();
    
    // Spriting does not work on current mobile hardware
    HPS::HighlightOperator *op = new HPS::HighlightOperator();
    HPS::HighlightOptionsKit kit = op->GetHighlightOptions();
    kit.SetOverlay(HPS::Drawing::Overlay::NoOverlay);
    op->SetHighlightOptions(kit);
	
    GetCanvas().GetFrontView().GetOperatorControl().Push(op);
}

void UserMobileSurface::setOperatorSelectArea()
{
	GetCanvas().GetFrontView().GetOperatorControl().Pop();
    
    // Spriting does not work on current mobile hardware
    HPS::HighlightAreaOperator *op = new HPS::HighlightAreaOperator();
    HPS::HighlightOptionsKit kit = op->GetHighlightOptions();
    kit.SetOverlay(HPS::Drawing::Overlay::NoOverlay);
    op->SetHighlightOptions(kit);
    
    
	GetCanvas().GetFrontView().GetOperatorControl().Push(op);
}

void UserMobileSurface::onModeSimpleShadow(bool enable)
{
	if (!isValid())
		return;

    if (enable == true)
    {
        // Set simple shadow options
        const float					opacity = 0.3f;
        const unsigned int			resolution = 512;
        const unsigned int			blurring = 20;
        
        // Set opacity in simple shadow color
        HPS::RGBAColor				color(0.4f, 0.4f, 0.4f, opacity);
        if (GetCanvas().GetFrontView().GetSegmentKey().GetVisualEffectsControl().ShowSimpleShadowColor(color))
            color.alpha = opacity;

        GetCanvas().GetFrontView().GetSegmentKey().GetVisualEffectsControl()
            .SetSimpleShadow(enable, resolution, blurring)
            .SetSimpleShadowColor(color);
    }

    GetCanvas().GetFrontView().SetSimpleShadow(enable);
    GetCanvas().Update();
}

void UserMobileSurface::onModeSmooth()
{
	if (!isValid())
		return;

    // Toggle Phong on/off
    if (currentRenderingMode == HPS::Rendering::Mode::Phong)
        currentRenderingMode = HPS::Rendering::Mode::Default;
    else
        currentRenderingMode = HPS::Rendering::Mode::Phong;

	GetCanvas().GetFrontView().SetRenderingMode(currentRenderingMode);
	GetCanvas().Update();
}

void UserMobileSurface::onModeHiddenLine()
{
	if (!isValid())
		return;

    // Toggle hidden line
    if (currentRenderingMode == HPS::Rendering::Mode::FastHiddenLine)
        currentRenderingMode = HPS::Rendering::Mode::Default;
    else
    {
        currentRenderingMode = HPS::Rendering::Mode::FastHiddenLine;
        
        // fixed framerate is not compatible with hidden line
        if (frameRateEnabled)
        {
            GetCanvas().SetFrameRate(0);
            frameRateEnabled = false;
        }
    }

	GetCanvas().GetFrontView().SetRenderingMode(currentRenderingMode);
	GetCanvas().Update();
}

void UserMobileSurface::onModeFrameRate()
{
	if (!isValid())
		return;

	const float					frameRate = 20.0f;

	// Toggle frame rate and set.  Note that 0 disables frame rate.
    frameRateEnabled = !frameRateEnabled;
    
	if (frameRateEnabled)
    {
		GetCanvas().SetFrameRate(frameRate);
        
        // fixed framerate is not compatible with hidden line
        if (currentRenderingMode == HPS::Rendering::Mode::FastHiddenLine)
        {
            currentRenderingMode = HPS::Rendering::Mode::Default;
            GetCanvas().GetFrontView().SetRenderingMode(currentRenderingMode);
        }
    }
	else
		GetCanvas().SetFrameRate(0);

	GetCanvas().Update();
}

void UserMobileSurface::onUserCode1()
{
	// TODO: Add your command handler code here
	dprintf("user code 1");
    insertcuttingSectonPlane(0);
}

void UserMobileSurface::onUserCode2()
{
	// TODO: Add your command handler code here
	dprintf("user code 2");
    insertcuttingSectonPlane(1);
}

void UserMobileSurface::onUserCode3()
{
	// TODO: Add your command handler code here
	dprintf("user code 3");
    insertcuttingSectonPlane(2);
}

void UserMobileSurface::onUserCode4()
{
	// TODO: Add your command handler code here
	dprintf("user code 4");
}

