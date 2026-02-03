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
    object Now : Screen("now/{nodeId}") {
        fun createRoute(nodeId: String) = "now/$nodeId"
    }
    object Tree : Screen("tree")
    object Stats : Screen("stats")
}

@Composable
fun UniversityNavGraph(navController: NavHostController) {
    NavHost(navController = navController, startDestination = Screen.Home.route) {
        composable(Screen.Home.route) {
            val viewModel: HomeViewModel = hiltViewModel()
            HomeScreen(
                uiState = viewModel.uiState.collectAsState().value,
                onNavigateToNow = { nodeId -> navController.navigate(Screen.Now.createRoute(nodeId)) },
                onNavigateToTree = { navController.navigate(Screen.Tree.route) },
                onNavigateToStats = { navController.navigate(Screen.Stats.route) },
                onModeChange = viewModel::setMode
            )
        }
        
        composable(Screen.Now.route) { backStackEntry ->
            val nodeId = backStackEntry.arguments?.getString("nodeId")
            NowScreen(
                nodeId = nodeId,
                onComplete = { navController.popBackStack() } // Return to Home after completion
            )
        }
        
        composable(Screen.Tree.route) {
            TreeScreen(
                onBack = { navController.popBackStack() }
            )
        }
        
        composable(Screen.Stats.route) {
            StatsScreen(
                onBack = { navController.popBackStack() }
            )
        }
    }
}
