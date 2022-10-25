#pragma once

#include "MobileSurface.h"

#define SURFACE_ACTION

// UserMobileSurface is a plaform-independent class which contains user-defined
//  action methods called by Android/iOS gui code.  This class (along with MobileApp)
//  allow Android/iOS gui code to communicate with C++ mobile independent code.

// Methods acting on a surface should be declared here.

// Methods to be exposed to platform specific gui code (Android Java, iOS Objective C++)
//  should be prefixed with SURFACE_ACTION.
// The following rules hold for SURFACE_ACTION methods:
// * Methods should be declared on one line (multi-line declarations not yet supported)
// * The following parameters are valid:
//   - 'const char *': used for input strings.  Translates to String in Java
//   - 'char *': used for output strings.  Translates to StringBuffer in Java
//   - 'int': used for input int
//   - 'int name[]': used for input/output array
//   -  float/double can be used like 'int' above
// * The following return values are valid:
//   - void, bool, int, float, double

class UserMobileSurface : public MobileSurface
{
public:
	UserMobileSurface();
	virtual ~UserMobileSurface();

	virtual bool			bind(void *window);
	virtual void			singleTap(int x, int y);
	virtual void			doubleTap(int x, int y, HPS::TouchID id);

	void					SetMainDistantLight(HPS::Vector const & lightDirection = HPS::Vector(1, 0, -1.5f));
    void                    SetMainDistantLight(HPS::DistantLightKit const & light);
	void					SetupSceneDefaults();

	SURFACE_ACTION bool		loadFile(const char *fileName);

    SURFACE_ACTION void     segControlValueChanged(long index);
    
	SURFACE_ACTION void		setOperatorOrbit();
	SURFACE_ACTION void		setOperatorZoomArea();
    SURFACE_ACTION void		setOperatorFly();
	SURFACE_ACTION void		setOperatorSelectPoint();
	SURFACE_ACTION void		setOperatorSelectArea();
	
	SURFACE_ACTION void		onModeSimpleShadow(bool enable);
	SURFACE_ACTION void		onModeSmooth();
	SURFACE_ACTION void		onModeHiddenLine();
	SURFACE_ACTION void		onModeFrameRate();
	
	SURFACE_ACTION void		onUserCode1();
	SURFACE_ACTION void		onUserCode2();
	SURFACE_ACTION void		onUserCode3();
	SURFACE_ACTION void		onUserCode4();

private:

	void 					loadCamera(HPS::View & view, HPS::Stream::ImportResultsKit const & results);

	// User code 1 test
	bool					displayResourceMonitor;

	HPS::DistantLightKey	mainDistantLight;
	HPS::Rendering::Mode	currentRenderingMode;
    HPS::CuttingSectionOperator *cuttingOperatorPtr;
    bool                    frameRateEnabled;
    
    void removecuttingSection();
    void addcuttingSection();
    void insertcuttingSectonPlane(int index);
    
    bool importHSFFile(const char * filename, HPS::Model const & model, HPS::Stream::ImportResultsKit &);
    bool importSTLFile(const char * filename, HPS::Model const & model);
    bool importOBJFile(const char * filename, HPS::Model const & model);
#ifdef USING_EXCHANGE
    bool importPRCFile(const char * filename);
    bool importU3DFile(const char * filename);
#endif
};

