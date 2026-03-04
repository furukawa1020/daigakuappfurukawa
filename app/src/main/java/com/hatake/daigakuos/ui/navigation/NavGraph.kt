package com.hatake.daigakuos.ui.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.compose.runtime.collectAsState
import androidx.hilt.navigation.compose.hiltViewModel
import com.hatake.daigakuos.ui.home.HomeScreen
import com.hatake.daigakuos.ui.home.HomeViewModel
import com.hatake.daigakuos.ui.now.NowScreen
import com.hatake.daigakuos.ui.tree.TreeScreen
import com.hatake.daigakuos.ui.stats.StatsScreen

sealed class Screen(val route: String) {
    object Home : Screen("home")
    object Now : Screen("now/{nodeId}?targetMinutes={targetMinutes}") {
        fun createRoute(nodeId: String, targetMinutes: Int? = null) = 
            if (targetMinutes != null) "now/$nodeId?targetMinutes=$targetMinutes" else "now/$nodeId"
    }
    object Tree : Screen("tree")
    object Stats : Screen("stats")
    object Settings : Screen("settings")
    object Collection : Screen("collection")
}

@Composable
fun UniversityNavGraph(navController: NavHostController) {
    NavHost(navController = navController, startDestination = Screen.Home.route) {
        composable(Screen.Home.route) {
            val viewModel: HomeViewModel = hiltViewModel()
            HomeScreen(
                uiState = viewModel.uiState.collectAsState().value,
                onNavigateToNow = { nodeId, target -> navController.navigate(Screen.Now.createRoute(nodeId, target)) },
                onNavigateToTree = { navController.navigate(Screen.Tree.route) },
                onNavigateToStats = { navController.navigate(Screen.Stats.route) },
                onNavigateToSettings = { navController.navigate(Screen.Settings.route) },
                onNavigateToCollection = { navController.navigate(Screen.Collection.route) },
                onModeChange = viewModel::setMode
            )
        }
        
        composable(
            route = Screen.Now.route,
            arguments = listOf(
                androidx.navigation.navArgument("nodeId") { type = androidx.navigation.NavType.StringType },
                androidx.navigation.navArgument("targetMinutes") { 
                    type = androidx.navigation.NavType.IntType 
                    defaultValue = -1 
                }
            )
        ) { backStackEntry ->
            val nodeId = backStackEntry.arguments?.getString("nodeId")
            // Handle "null" string from navigation if any, or logic
            val safeNodeId = if(nodeId == "null") null else nodeId
            
            val targetMinutesArg = backStackEntry.arguments?.getInt("targetMinutes") ?: -1
            val safeTargetMinutes = if (targetMinutesArg == -1) null else targetMinutesArg
            
            NowScreen(
                nodeId = safeNodeId,
                targetMinutes = safeTargetMinutes,
                onComplete = { sessionId, minutes ->
                    navController.navigate("finish/$sessionId/$minutes") {
                         popUpTo(Screen.Home.route) { inclusive = false } // Don't allow back to Now
                    }
                }
            )
        }
        
        composable("finish/{sessionId}/{minutes}") { backStackEntry ->
            val sessionId = backStackEntry.arguments?.getString("sessionId") ?: ""
            val minutes = backStackEntry.arguments?.getString("minutes")?.toIntOrNull() ?: 25
            com.hatake.daigakuos.ui.finish.FinishScreen(
                sessionId = sessionId,
                elapsedMinutes = minutes,
                onFinish = {
                    navController.navigate(Screen.Home.route) {
                        popUpTo(Screen.Home.route) { inclusive = true }
                    }
                }
            )
        }
        
        composable(Screen.Tree.route) {
            TreeScreen(
                onBack = { navController.popBackStack() },
                onNavigateToNow = { nodeId ->
                    navController.navigate(Screen.Now.createRoute(nodeId))
                }
            )
        }
        
        composable(Screen.Stats.route) {
            StatsScreen(
                onBack = { navController.popBackStack() }
            )
        }

        composable(Screen.Settings.route) {
            com.hatake.daigakuos.ui.settings.SettingsScreen(
                onBack = { navController.popBackStack() }
            )
        }

        composable(Screen.Collection.route) {
            com.hatake.daigakuos.ui.collection.MokoCollectionScreen(
                onBack = { navController.popBackStack() }
            )
        }
    }
}
