#ifndef BIGI_PRAGMA_STAGEDEFINES_INCLUDED
#define BIGI_PRAGMA_STAGEDEFINES_INCLUDED


#pragma multi_compile_local_vertex BIGI_VERTEX_STAGE
#pragma multi_compile_local_fragment BIGI_FRAGMENT_STAGE
#pragma multi_compile_local_hull BIGI_HULL_STAGE
#pragma multi_compile_local_domain BIGI_DOMAIN_STAGE
#pragma multi_compile_local_geometry BIGI_GEOMETRY_STAGE
#pragma multi_compile_local_raytracing BIGI_RAYTRACING_STAGE

#if defined(BIGI_VERTEX_STAGE)
#if defined(BIGI_FRAGMENT_STAGE) || defined(BIGI_HULL_STAGE) || defined(BIGI_DOMAIN_STAGE) || defined(BIGI_GEOMETRY_STAGE) || defined(BIGI_RAYTRACING_STAGE)
#warning "Shader compiling weirdly, too many stage keywords active"
#endif
#endif

#if defined(BIGI_FRAGMENT_STAGE)
#if defined(BIGI_VERTEX_STAGE) || defined(BIGI_HULL_STAGE) || defined(BIGI_DOMAIN_STAGE) || defined(BIGI_GEOMETRY_STAGE) || defined(BIGI_RAYTRACING_STAGE)
#warning "Shader compiling weirdly, too many stage keywords active"
#endif
#endif

#if defined(BIGI_HULL_STAGE)
#if defined(BIGI_FRAGMENT_STAGE) || defined(BIGI_VERTEX_STAGE) || defined(BIGI_DOMAIN_STAGE) || defined(BIGI_GEOMETRY_STAGE) || defined(BIGI_RAYTRACING_STAGE)
#warning "Shader compiling weirdly, too many stage keywords active"
#endif
#endif

#if defined(BIGI_DOMAIN_STAGE)
#if defined(BIGI_FRAGMENT_STAGE) || defined(BIGI_VERTEX_STAGE) || defined(BIGI_HULL_STAGE) || defined(BIGI_GEOMETRY_STAGE) || defined(BIGI_RAYTRACING_STAGE)
#warning "Shader compiling weirdly, too many stage keywords active"
#endif
#endif

#if defined(BIGI_GEOMETRY_STAGE)
#if defined(BIGI_FRAGMENT_STAGE) || defined(BIGI_VERTEX_STAGE) || defined(BIGI_HULL_STAGE) || defined(BIGI_DOMAIN_STAGE) || defined(BIGI_RAYTRACING_STAGE)
#warning "Shader compiling weirdly, too many stage keywords active"
#endif
#endif

#if defined(BIGI_RAYTRACING_STAGE)
#if defined(BIGI_FRAGMENT_STAGE) || defined(BIGI_VERTEX_STAGE) || defined(BIGI_HULL_STAGE) || defined(BIGI_DOMAIN_STAGE) || defined(BIGI_GEOMETRY_STAGE)
#warning "Shader compiling weirdly, too many stage keywords active"
#endif
#endif

#endif