
#include "MobileApp.h"
#include "dprintf.h"

#include "visualize_license.h"

MobileApp::MobileApp()
	: _world(0)
{
	_world = new HPS::World(VISUALIZE_LICENSE);

	// Subscribe _errorHandler to handle errors
	HPS::Database::GetEventDispatcher().Subscribe(_errorHandler, HPS::Object::ClassID<HPS::ErrorEvent>());

	// Subscribe _warningHandler to handle warnings
	HPS::Database::GetEventDispatcher().Subscribe(_warningHandler, HPS::Object::ClassID<HPS::WarningEvent>());

}

void MobileApp::setFontDirectory(const char* fontDir)
{
	_world->SetFontDirectory(fontDir);
}

void MobileApp::setMaterialsDirectory(const char* materialsDir)
{
	_world->SetMaterialLibraryDirectory(materialsDir);
}

